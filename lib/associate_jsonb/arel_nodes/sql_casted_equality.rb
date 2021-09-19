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
