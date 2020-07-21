# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module SchemaCreation
      private
        def visit_AlterTable(o)
          sql = super
          sql << o.constraint_adds.map {|ct| visit_AddConstraint ct }.join(" ")
          sql << o.constraint_drops.map {|ct| visit_DropConstraint ct }.join(" ")
          add_jsonb_function(o, sql)
        end

        def visit_TableDefinition(...)
          add_jsonb_function(o, super(...))
        end

        def visit_ColumnDefinition(o)
          column_sql = super
          add_column_constraint!(o, column_sql, column_options(o))
          column_sql
        end

        def visit_ConstraintDefinition(o)
          +<<-SQL.squish
            CONSTRAINT #{o.name} CHECK (#{o.value})
          SQL
        end

        def visit_AddConstraint(o)
          "ADD #{accept(o)}"
        end

        def visit_DropConstraint(o)
          "DROP CONSTRAINT #{o.name}"
        end

        def add_column_constraint!(o, sql, options)
          if options[:constraint]
            name = value = nil
            if options[:constraint].is_a?(Hash)
              name = quote_column_name(options[:constraint][:name]).presence
              value = options[:constraint][:value]
            else
              value = options[:constraint]
            end
            name ||= quote_column_name("#{o.name}_constraint_#{value.hash}")
            sql << " CONSTRAINT #{name} CHECK (#{value})"
          end

          sql
        end

        def add_jsonb_function(o, sql)
          if sql =~ /jsonb_foreign_key/
            visit_AddJsonForeignKeyFunction(o) + sql
          else
            sql
          end
        end
    end
  end
end
