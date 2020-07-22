# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module AlterTable # :nodoc:
      attr_reader :constraint_adds, :constraint_drops
      def initialize(td)
        super
        @constraint_adds = []
        @constraint_drops = []
      end

      def add_constraint(name = nil, **opts)
        unless opts[:value].present?
          raise ArgumentError.new("Invalid Add Constraint Options")
        end

        @constraint_adds << ConstraintDefinition.new(
          **opts.reverse_merge(name: name)
        )
      end

      def alter_constraint(name = nil, **opts)
        opts[:force] = true
        add_constraint(name, **opts)
      end

      def drop_constraint(name = nil, **opts)
        opts = opts.reverse_merge(force: true, name: name, value: nil)

        unless opts[:name].present? || opts[:value].present?
          raise ArgumentError.new("Invalid Drop Constraint Options")
        end

        @constraint_drops << ConstraintDefinition.new(**opts)
      end
    end
  end
end
