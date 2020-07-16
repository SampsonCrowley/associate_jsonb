# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module AssociationScope #:nodoc:

      def get_chain(reflection, association, tracker)
        name = reflection.name
        chain = [ActiveRecord::Reflection::RuntimeReflection.new(reflection, association)]
        reflection.chain.drop(1).each do |refl|
          aliased_table = tracker.aliased_table_for(
            refl.table_name,
            refl.alias_candidate(name),
            refl.klass.type_caster,
            refl.klass.store_column_attribute_tracker
          )
          chain << ActiveRecord::Associations::AssociationScope::ReflectionProxy.new(refl, aliased_table)
        end
        chain
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def last_chain_scope(scope, owner_reflection, owner)
        reflection = owner_reflection.instance_variable_get(:@reflection)
        return super unless reflection&.foreign_store?


        join_keys = owner_reflection.join_keys
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
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def apply_jsonb_equality(scope, table, jsonb_column, store_key, foreign_key, value, foreign_klass)
        sql_type = type = node_klass = nil
        begin
          type = foreign_klass.attribute_types[foreign_key.to_s]
          raise "type not found" unless type.present?
          sql_type = foreign_klass.columns_hash[foreign_key.to_s]
          raise "not a column" unless sql_type.present?
          sql_type = sql_type.sql_type
          node_klass = Arel::Nodes::Jsonb::DashArrow
        rescue
          type = ActiveModel::Type::String.new
          sql_type = "text"
          node_klass = Arel::Nodes::Jsonb::DashDoubleArrow
        end

        scope.where!(
          Arel::Nodes::SqlCastedEquality.new(
            node_klass.new(table, table[jsonb_column], store_key),
            sql_type,
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
