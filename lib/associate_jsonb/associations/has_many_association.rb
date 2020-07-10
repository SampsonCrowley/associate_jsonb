# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module HasManyAssociation #:nodoc:
      def ids_reader
        return super unless reflection.jsonb_store?

        Array(
          owner[reflection.jsonb_store_attr][
            reflection.habtm_store_key
          ]
        )
      end

      # rubocop:disable Naming/AccessorMethodName
      def set_owner_attributes(record)
        return super unless reflection.jsonb_store?

        creation_attributes.each do |key, value|
          if key == reflection.jsonb_store_attr
            set_store_attributes(record, key, value)
          else
            record[key] = value
          end
        end
      end
      # rubocop:enable Naming/AccessorMethodName

      def set_store_attributes(record, store_column, attributes)
        attributes.each do |key, value|
          if value.is_a?(Array)
            # record[store_column][key] ||= []
            # record[store_column][key] =
            #   record[store_column][key].concat(value).uniq
            record.__send__("#{key}=", []) unless record.__send__("#{key}")
            record.__send__("#{key}=", (record.__send__("#{key}") | value).sort)
          else
            # record[store_column] = value
            record.__send__("#{key}=", value.presence)
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      def creation_attributes
        return super unless reflection.options.key?(:store)
        {}
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def insert_record(record, validate = true, raise = false)
        super.tap do |super_result|
          next unless reflection.jsonb_store? && super_result

          method = reflection.active_record_primary_key || "#{reflection.name.to_s.singularize}_ids".to_sym
          arr = (
                  Array(owner[method]).uniq.select(&:present?) \
                  | [ record[reflection.foreign_key] ]
                ).sort
          owner.update(method => arr)
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def delete_records(records, method)
        return super unless options.key?(:store)
        super(records, :delete)
      end

      # rubocop:disable Metrics/AbcSize
      def delete_count(method, scope)
        store = reflection.foreign_store_attr ||
                reflection.jsonb_store_attr
        return super if method == :delete_all || !store

        if reflection.options.key?(:foreign_store)
          remove_jsonb_foreign_id_on_belongs_to(store, reflection.foreign_key)
        else
          remove_jsonb_foreign_id_on_habtm(
            store, reflection.habtm_store_key, owner.id
          )
        end
      end
      # rubocop:enable Metrics/AbcSize

      def remove_jsonb_foreign_id_on_belongs_to(store, foreign_key)
        scope.update_all("#{store} = #{store} #- '{#{foreign_key}}'")
      end

      def remove_jsonb_foreign_id_on_habtm(store, foreign_key, owner_id)
        # PostgreSQL can only delete jsonb array elements by text or index.
        # Therefore we have to convert the jsonb array to PostgreSQl array,
        # remove the element, and convert it back
        scope.update_all(
          Arel::Nodes::SqlLiteral.new(
            <<-SQL.squish
              #{store} = jsonb_set(
                #{store},
                '{#{foreign_key}}',
                to_jsonb(
                  array_remove(
                    array(
                      select * from jsonb_array_elements(
                        (#{store}->'#{foreign_key}')
                      )
                    ),
                    '#{owner_id}'
                  )
                )
              )
            SQL
          )
        )
      end
    end
  end
end
