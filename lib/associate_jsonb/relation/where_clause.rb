# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Relation
    module WhereClause
      def to_h(table_name = nil, equality_only: false)
        equalities(predicates, equality_only).each_with_object({}) do |node, hash|
          next if table_name&.!= node.original_left.relation.name
          name = node.original_left.name.to_s
          value = extract_node_value(node.right)
          hash[name] = value
        end
      end
    end
  end
end
