module ActiveRecord
  module JSONB
    module Associations
      module AssociationScope #:nodoc:
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def last_chain_scope(scope, owner_reflection, owner)
          reflection = owner_reflection.instance_variable_get(:@reflection)
          return super unless reflection

          table = owner_reflection.aliased_table
          join_keys = owner_reflection.join_keys
          key = join_keys.key
          value = transform_value(owner[join_keys.foreign_key])

          if reflection.options.key?(:foreign_store)
            apply_jsonb_equality(
              scope,
              table,
              reflection.options[:foreign_store],
              key,
              value
            )
          elsif reflection.options.key?(:store)
            return super if reflection.belongs_to?
            pluralized_key = key.pluralize

            apply_jsonb_containment(
              scope,
              table,
              reflection.options[:store],
              pluralized_key,
              value
            )
          else
            super
          end
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        def apply_jsonb_equality(scope, table, jsonb_column, key, value)
          scope.where!(
            Arel::Nodes::JSONBDashDoubleArrow.new(
              table, table[jsonb_column], key
            ).eq(
              Arel::Nodes::BindParam.new(
                Relation::QueryAttribute.new(
                  key.to_s, value, ActiveModel::Type::String.new
                )
              )
            )
          )
        end

        def apply_jsonb_containment(scope, table, jsonb_column, key, value)
          scope.where!(
            Arel::Nodes::JSONBHashArrow.new(
              table, table[jsonb_column], key
            ).contains(
              Arel::Nodes::BindParam.new(
                Relation::QueryAttribute.new(
                  key.to_s, value, ActiveModel::Type::String.new
                )
              )
            )
          )
        end
      end
    end
  end
end
