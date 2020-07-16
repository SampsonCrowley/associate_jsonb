# encoding: utf-8
# frozen_string_literal: true

# module AssociateJsonb
#   module ArelNodes
#     class SqlCastedEquality < ::Arel::Nodes::Equality
#       attr_reader :original_left
#       def initialize(left, cast_as, right)
#         @original_left = left
#         super(
#           ::Arel::Nodes::NamedFunction.new(
#             "CAST",
#             [ left.as(cast_as) ]
#           ),
#           right
#         )
#       end
#     end
#   end
# end


# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    class SqlCastedEquality < AssociateJsonb::ArelNodes::SqlCastedBinary
      def operator; :== end
      alias :operand1 :left
      alias :operand2 :right
    end
  end
end
