# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module ForeignAssociation # :nodoc:
      private
        # Sets the owner attributes on the given record
        def set_owner_attributes(record)
          return if options[:through]
          return super unless reflection.foreign_store?

          jsonb_store = reflection.foreign_store_attr.to_s
          value = record._read_attribute(jsonb_store).presence || {}
          fk_value = owner._read_attribute(reflection.join_foreign_key)
          value[reflection.foreign_store_key] = fk_value

          record._write_attribute(reflection.join_primary_key, fk_value)
          record._write_attribute(jsonb_store, value)
        end
    end
  end
end
