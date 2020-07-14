# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class BindableOperator < AssociateJsonb::ArelNodes::Jsonb::Operator
        def right_side
          return name if name.is_a?(::Arel::Nodes::BindParam) ||
                         name.is_a?(::Arel::Nodes::SqlLiteral)

          ::Arel::Nodes::SqlLiteral.new("'#{name.as_json}'")
        end
      end
    end
  end
end
