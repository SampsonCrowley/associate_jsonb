# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module AssociationScope #:nodoc:
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def last_chain_scope(scope, owner_reflection, owner)
        reflection = owner_reflection.instance_variable_get(:@reflection)
        return super unless reflection


        join_keys = owner_reflection.join_keys

        if reflection.foreign_store?
          table = owner_reflection.aliased_table
          key = reflection.foreign_store_key || join_keys.key
          value = transform_value(owner[join_keys.foreign_key])

          apply_jsonb_equality(
            scope,
            table,
            reflection.foreign_store_attr,
            key.to_s,
            join_keys.foreign_key,
            value,
            reflection.active_record
          )
        elsif !reflection.belongs_to? && reflection.jsonb_store?
          table = owner_reflection.aliased_table
          primary_key = reflection.join_primary_key
          foreign_key = reflection.join_foreign_key
          value = owner[foreign_key]

          scope.where(table[primary_key].in(value))
        else
          super
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def apply_jsonb_equality(scope, table, jsonb_column, store_key, foreign_key, value, ref_klass)
        type = node_klass = nil
        begin
          type = ActiveRecord::Type.lookup(ref_klass.columns_hash[foreign_key.to_s].type)
          node_klass = Arel::Nodes::Jsonb::DashArrow
        rescue
          type = ActiveModel::Type::String.new
          node_klass = Arel::Nodes::Jsonb::DashDoubleArrow
        end
        scope.where!(
          Arel::Nodes::Jsonb::DashArrow.new(
            table, table[jsonb_column], store_key
          ).eq(
            Arel::Nodes::BindParam.new(
              ActiveRecord::Relation::QueryAttribute.new(
                store_key, value, type
              )
            )
          )
        )
      end
    end
  end
end
