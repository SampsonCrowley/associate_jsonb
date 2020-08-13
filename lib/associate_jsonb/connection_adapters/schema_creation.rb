# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module SchemaCreation
      private
        def visit_AlterTable(o)
          sql = super
          sql << o.constraint_adds.map {|ct| visit_AddConstraint ct }.join(" ")
          sql << o.constraint_drops.map {|ct| visit_DropConstraint ct }.join(" ")
          sql
        end

        def visit_TableDefinition(o)
          create_sql = +"CREATE#{table_modifier_in_create(o)} TABLE "
          create_sql << "IF NOT EXISTS " if o.if_not_exists
          create_sql << "#{quote_table_name(o.name)} "

          statements = o.columns.map { |c| accept c }
          statements << accept(o.primary_keys) if o.primary_keys

          if supports_indexes_in_create?
            statements.concat(o.indexes.map { |column_name, options| index_in_create(o.name, column_name, options) })
          end

          if supports_foreign_keys?
            statements.concat(o.foreign_keys.map { |to_table, options| foreign_key_in_create(o.name, to_table, options) })
            # statements.concat(o.constraints.map { |ct| visit_ConstraintDefinition(ct) })
          end

          create_sql << "(#{statements.join(', ')})" if statements.present?
          add_table_options!(create_sql, table_options(o))
          create_sql << " AS #{to_sql(o.as)}" if o.as
          create_sql
        end

        def visit_ConstraintDeferral(o)
          return "" unless o.deferrable_default?
          return "NOT DEFERRABLE" unless o.deferrable?
          initial =
            case o.deferrable
            when :immediate
              "IMMEDIATE"
            else
              "DEFERRED"
            end
          "DEFERRABLE INITIALLY #{initial}"
        end

        def visit_ConstraintDefinition(o)
          +<<-SQL.squish
            CONSTRAINT #{quote_column_name(o.name)}
            CHECK (#{o.value})
              #{visit_ConstraintDeferral(o)}
              #{o.not_valid? ? "NOT VALID" : ''}
          SQL
        end

        def visit_AddConstraint(o)
          sql = +""
          if o.force?
            sql << visit_DropConstraint(o)
            sql << " "
          end
          sql << "ADD #{accept(o)}"
        end

        def visit_DropConstraint(o, if_exists: false)
          +<<-SQL.squish
            DROP CONSTRAINT #{quote_column_name(o.name)}
              #{o.force? ? "IF EXISTS" : ""}
          SQL
        end

        def visit_AddJsonbForeignKeyFunction(*)
          <<~SQL
            CREATE OR REPLACE FUNCTION jsonb_foreign_key
              (
                table_name text,
                foreign_key text,
                store jsonb,
                key text,
                type text default 'numeric',
                nullable boolean default TRUE
              )
            RETURNS BOOLEAN AS
            $BODY$
            DECLARE
              does_exist BOOLEAN;
            BEGIN
              IF store->>key IS NULL
              THEN
                return nullable;
              END IF;

              IF store->>key = ''
              THEN
                return FALSE;
              END IF;

              EXECUTE FORMAT('SELECT EXISTS (SELECT 1 FROM %1$I WHERE %1$I.%2$I = CAST($1 AS ' || type || '))', table_name, foreign_key)
              INTO does_exist
              USING store->>key;

              RETURN does_exist;
            END;
            $BODY$
            LANGUAGE plpgsql;

          SQL
        end

        def visit_AddJsonbNestedSetFunction(*)
          <<~SQL
            CREATE OR REPLACE FUNCTION jsonb_nested_set
              (
                target jsonb,
                path text[],
                new_value jsonb
              )
            RETURNS jsonb AS
            $BODY$
            DECLARE
              new_json jsonb := '{}'::jsonb;
              does_exist BOOLEAN;
              current_path text[];
              key text;
            BEGIN
              IF target #> path IS NOT NULL
              THEN
                return jsonb_set(target, path, new_value);
              ELSE
                new_json := target;

                IF array_length(path, 1) > 1
                THEN
                  FOREACH key IN ARRAY path[:(array_length(path, 1) - 1)]
                  LOOP
                    current_path := array_append(current_path, key);
                    IF new_json #> current_path IS NULL
                    THEN
                      new_json := jsonb_set(new_json, current_path, '{}'::jsonb, TRUE);
                    END IF;
                  END LOOP;
                END IF;

                return jsonb_set(new_json, path, new_value, TRUE);
              END IF;
            END;
            $BODY$
            LANGUAGE plpgsql;
          SQL
        end

        def add_column_options!(sql, opts)
          super

          if constraint_opts = opts[:constraint]
            constraint_opts = { value: constraint_opts } unless constraint_opts.is_a?(Hash)
            sql << " #{accept(ConstraintDefinition.new(**constraint_opts))}"
          end

          sql
        end
    end
  end
end
