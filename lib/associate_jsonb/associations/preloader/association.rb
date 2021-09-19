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

        private
          def load_records
            return super unless reflection.foreign_store?
            # owners can be duplicated when a relation has a collection association join
            # #compare_by_identity makes such owners different hash keys
            @records_by_owner = {}.compare_by_identity
            raw_records = owner_keys.empty? ? [] : records_for(owner_keys)

            @preloaded_records = raw_records.select do |record|
              assignments = false

              owners_by_key[convert_key(record[association_key_name])].each do |owner|
                entries = (@records_by_owner[owner] ||= [])

                if reflection.collection? || entries.empty?
                  entries << record
                  assignments = true
                end
              end

              assignments
            end
          end
      end
    end
  end
end
