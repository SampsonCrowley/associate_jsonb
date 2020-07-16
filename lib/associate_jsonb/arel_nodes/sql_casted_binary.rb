# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    class SqlCastedBinary < ::Arel::Nodes::Binary
      attr_reader :original_left
      def initialize(left, cast_as, right)
        @original_left = left
        super(
          ::Arel::Nodes::NamedFunction.new(
            "CAST",
            [ left.as(cast_as) ]
          ),
          right
        )
      end
    end
  end
end
