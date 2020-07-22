# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module TableDefinition
      attr_reader :constraints

      def initialize(*,**)
        super
        @constraints = []
      end

      def constraint(name = nil, **opts)
        unless opts[:value].present?
          raise ArgumentError.new("Invalid Drop Constraint Options")
        end

        @constraints << ConstraintDefinition.new(
          **opts.reverse_merge(name: name)
        )
      end
    end
  end
end
