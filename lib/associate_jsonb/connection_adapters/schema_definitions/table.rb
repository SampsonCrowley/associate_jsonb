# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module Table
      def constraint(**opts)
        @base.add_constraint(name, **opts)
      end
    end
  end
end
