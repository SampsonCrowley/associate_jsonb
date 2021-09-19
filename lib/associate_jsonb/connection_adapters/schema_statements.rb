# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module SchemaStatements
      def add_jsonb_nested_set_function
        execute schema_creation.accept(AddJsonbNestedSetFunction.new)
      end

      def add_jsonb_foreign_key_function
        execute schema_creation.accept(AddJsonbForeignKeyFunction.new)
      end

      def create_table(table_name, id: :primary_key, primary_key: nil, force: nil, **options)
        td = create_table_definition(table_name, **extract_table_options!(options))

        if id && !td.as
          pk = primary_key || ActiveRecord::Base.get_primary_key(table_name.to_s.singularize)

          if id.is_a?(Hash)
            options.merge!(id.except(:type))
            id = id.fetch(:type, :primary_key)
          end

          if pk.is_a?(Array)
            td.primary_keys pk
          else
            td.primary_key pk, id, **options
          end
        end

        yield td if block_given?

        if force
          drop_table(table_name, force: force, if_exists: true)
        else
          schema_cache.clear_data_source_cache!(table_name.to_s)
        end

        result = execute schema_creation.accept td

        td.indexes.each do |column_name, index_options|
          add_index(table_name, column_name, **index_options, if_not_exists: td.if_not_exists)
        end

        td.constraints.each do |ct|
          add_constraint(table_name, **ct)
        end

        if table_comment = td.comment.presence
          change_table_comment(table_name, table_comment)
        end

        td.columns.each do |column|
          change_column_comment(table_name, column.name, column.comment) if column.comment.present?
        end

        result
      end

      def add_constraint(table_name, **options)
        at = create_alter_table table_name
        at.add_constraint(**options)
        execute schema_creation.accept at
      end

      def constraints(table_name) # :nodoc:
        scope = quoted_scope(table_name)

        result = query(<<~SQL, "SCHEMA")
          SELECT
            con.oid,
            con.conname,
            con.connamespace,
            con.contype,
            con.condeferrable,
            con.condeferred,
            con.convalidated,
            pg_get_constraintdef(con.oid) as consrc
          FROM pg_catalog.pg_constraint con
          INNER JOIN pg_catalog.pg_class rel
                     ON rel.oid = con.conrelid
          INNER JOIN pg_catalog.pg_namespace nsp
                     ON nsp.oid = connamespace
          WHERE nsp.nspname = #{scope[:schema]}
          AND rel.relname = #{scope[:name]}
          ORDER BY rel.relname
        SQL

        result.map do |row|
          {
            oid: row[0],
            name: row[1],
            deferrable: row[4],
            deferred: row[5],
            validated: row[6],
            definition: row[7],
            type:
              case row[3].to_s.downcase
              when "c"
                "CHECK"
              when "f"
                "FOREIGN KEY"
              when "p"
                "PRIMARY KEY"
              when "u"
                "UNIQUE"
              when "t"
                "TRIGGER"
              when "x"
                "EXCLUDE"
              else
                "UNKNOWN"
              end
          }
        end
      end
    end
  end
end
