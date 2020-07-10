# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Preloader
      module Association #:nodoc:
        def records_for(ids)
          return super if reflection.belongs_to?
          return super unless reflection.jsonb_store? || reflection.foreign_store?

          join_keys = reflection.join_keys

          if reflection.foreign_store?
            table = reflection.klass.arel_table
            key = reflection.options[:foreign_store_key] || association_key_name
            scope.where(
              Arel::Nodes::Jsonb::HashArrow.new(
                table,
                table[reflection.foreign_store_attr],
                key
              ).intersects_with(ids)
            )
          elsif reflection.jsonb_store?
            table = reflection.active_record.arel_table
            key = reflection.options[:store_key] || "#{reflection.name.to_s.singularize}_ids"

            scope.where(
              Arel::Nodes::Jsonb::HashArrow.new(
                table,
                table[reflection.jsonb_store_attr],
                key
              ).intersects_with(ids)
            )
          end
        end
      end
    end
  end
end
