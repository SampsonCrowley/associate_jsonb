# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelExtensions
    module Nodes
      module TableAlias
        attr_reader :store_tracker

        def initialize(*args, store_columns: nil)
          @store_columns = store_columns
          super(*args)
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
end
