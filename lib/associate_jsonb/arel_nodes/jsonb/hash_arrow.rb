# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class HashArrow < AssociateJsonb::ArelNodes::Operator #:nodoc:
        def operator
          '#>'
        end

        def right_side
          ::Arel::Nodes::SqlLiteral.new("'{#{name}}'")
        end

        def contains(value)
          ArelNodes::Jsonb::AtArrow.new(relation, self, value)
        end

        def intersects_with(array)
          ::Arel::Nodes::InfixOperation.new(
            '>',
            ::Arel::Nodes::NamedFunction.new(
              'jsonb_array_length',
              [ ArelNodes::Jsonb::DoublePipe.new(relation, self, array) ]
            ),
            0
          )
        end
      end
    end
  end
end
