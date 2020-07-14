# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Reflection
    def jsonb_store?
      options.key?(:store) && jsonb_store_attr.present?
    end

    def jsonb_store_key?(fk = nil)
      options.key?(:store_key) \
      && options[:store_key].present? \
      && (!fk || (jsonb_store_key.to_s != fk.to_s))
    end

    def jsonb_store_attr
      options[:store]
    end

    def jsonb_store_key
      options[:store_key].presence || join_keys.foreign_key
    end

    def foreign_store?
      options.key?(:foreign_store) && options[:foreign_store].present?
    end

    def foreign_store_key?(fk = nil)
      options.key?(:foreign_store_key) \
      && options[:foreign_store_key].present? \
      && (!fk || (foreign_store_key.to_s != fk.to_s))
    end

    def foreign_store_attr
      options[:foreign_store]
    end

    def foreign_store_key
      options[:foreign_store_key].presence || join_keys.key
    end

    def join_scope(table, foreign_table, foreign_klass)
      return super unless jsonb_store? || foreign_store?

      predicate_builder = predicate_builder(table)
      scope_chain_items = join_scopes(table, predicate_builder)
      klass_scope       = klass_join_scope(table, predicate_builder)

      if type
        klass_scope.where!(type => foreign_klass.polymorphic_name)
      end

      scope_chain_items.inject(klass_scope, &:merge!)

      key         = join_keys.key
      foreign_key = join_keys.foreign_key

      if foreign_store?
        klass_scope.where!(
          Arel::Nodes::NamedFunction.new(
            "CAST",
            [
              Arel::Nodes::Jsonb::DashArrow.
                new(table, table[foreign_store_attr], foreign_store_key || key).
                as(foreign_klass.columns_hash[foreign_key.to_s].sql_type)
            ]
          ).eq(
            ::Arel::Nodes::SqlLiteral.
              new("#{foreign_table.name}.#{foreign_key}")
          )
        )

        # klass_scope.where!(
        #   Arel::Nodes::Jsonb::DashDoubleArrow.
        #     new(table, table[foreign_store_attr], foreign_store_key || key).
        #     eq(
        #       ::Arel::Nodes::SqlLiteral.
        #         new("#{foreign_table.name}.#{foreign_key}::text")
        #     )
        # )
      elsif jsonb_store?
        klass_scope.where!(
          Arel::Nodes::NamedFunction.new(
            "CAST",
            [
              Arel::Nodes::Jsonb::DashArrow.
                new(foreign_table, foreign_table[jsonb_store_attr], jsonb_store_key || foreign_key).
                as(klass.columns_hash[key.to_s].sql_type)
            ]
          ).eq(
            ::Arel::Nodes::SqlLiteral.new("#{table.name}.#{key}")
          )
        )
      end

      if klass.finder_needs_type_condition?
        klass_scope.where!(klass.send(:type_condition, table))
      end

      klass_scope
    end
  end
end
