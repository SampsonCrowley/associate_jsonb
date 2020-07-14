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
    end
  end
end
