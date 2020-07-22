# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    class ConstraintDefinition
      # rubocop:disable Metrics/ParameterLists
      attr_reader :name, :value, :not_valid, :deferrable, :force
      def initialize(value:, name: nil, not_valid: false, force: false, deferrable: true, **)
        @name = name.presence
        @value = value
        @not_valid = not_valid
        @deferrable = deferrable
        @force = force

        @name ||=
          "rails_constraint_" \
          "#{@value.hash}" \
          "_#{not_valid ? "nv" : "v"}" \
          "_#{deferrable ? "d" : "nd"}"
      end

      def deferrable_default?
        deferrable.nil?
      end


      def name?
        !!name
      end

      def value?
        !!value
      end

      def not_valid?
        !!not_valid
      end

      def deferrable?
        !!deferrable
      end

      def force?
        !!force
      end

      def to_h
        {
          name: name,
          value: value,
          not_valid: not_valid,
          deferrable: deferrable,
          force: force
        }
      end
      alias :to_hash :to_h
    end
  end
end
