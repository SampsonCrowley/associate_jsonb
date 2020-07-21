# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Relation
    module WhereClause
      def to_h(table_name = nil)
        equalities = equalities(predicates)
        if table_name
          equalities = equalities.select do |node|
            node.original_left.relation.name == table_name
          end
        end

        equalities.map { |node|
          name = node.original_left.name.to_s
          value = extract_node_value(node.right)
          [name, value]
        }.to_h
      end

      private
        def equalities(predicates)
          equalities = []

          predicates.each do |node|
            case node
            when Arel::Nodes::Equality, Arel::Nodes::SqlCastedEquality
              equalities << node
            when Arel::Nodes::And
              equalities.concat equalities(node.children)
            end
          end

          equalities
        end
    end
  end
end
