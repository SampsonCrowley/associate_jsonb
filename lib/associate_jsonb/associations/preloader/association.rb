# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Preloader
      module Association #:nodoc:
        def records_for(ids)
          return super if reflection.belongs_to?
          return super unless reflection.foreign_store?

          table = reflection.klass.arel_table
          scope.where(
            Arel::Nodes::Jsonb::HashArrow.new(
              table,
              table[reflection.foreign_store_attr],
              reflection.foreign_store_key
            ).intersects_with(ids)
          )
        end
      end
    end
  end
end
