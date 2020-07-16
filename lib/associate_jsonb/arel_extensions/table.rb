# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelExtensions
    module Table
      attr_reader :store_tracker

      def initialize(*args, store_tracker: nil, **opts)
        @store_tracker = store_tracker
        super(*args, **opts)
      end

      def alias(...)
        super(...).with_store_tracker(store_tracker)
      end

      def with_store_tracker(tracker)
        @store_tracker = tracker
        self
      end

      def [](name)
        return super unless store_col = store_tracker&.get(name)

        attr = ::Arel::Nodes::Jsonb::DashArrow.
          new(self, self[store_col[:store]], store_col[:key])

        if cast_as = (store_col[:cast] && store_col[:cast][:sql_type])
          attr = ::Arel::Nodes::NamedFunction.new(
            "CAST",
            [ attr.as(cast_as) ]
          )
        end

        Arel::Nodes::Jsonb::Attribute.new(self, name, attr)
      end
    end
  end
end
