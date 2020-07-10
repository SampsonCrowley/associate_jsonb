# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Association #:nodoc:
      private
        def creation_attributes
          return super if reflection.belongs_to?
          return super unless reflection.foreign_store? || reflection.jsonb_store?

          attributes = {}

          if reflection.foreign_store?
            jsonb_store = reflection.options[:foreign_store]
            attributes[jsonb_store] ||= {}
            attributes[jsonb_store][reflection.foreign_key] =
              owner[reflection.active_record_primary_key]
          end


          attributes
        end
    end
  end
end
