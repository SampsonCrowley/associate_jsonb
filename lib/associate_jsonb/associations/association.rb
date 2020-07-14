# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Association #:nodoc:
      def initialize_attributes(record, except_from_scope_attributes = nil) #:nodoc:
        super unless reflection.foreign_store? && reflection.foreign_store_key?(reflection.foreign_key)

        except_from_scope_attributes ||= {}
        skip_assign = [reflection.foreign_key, reflection.type, reflection.foreign_store_key].compact
        assigned_keys = record.changed_attribute_names_to_save
        assigned_keys += except_from_scope_attributes.keys.map(&:to_s)
        attributes = scope_for_create.except!(*(assigned_keys - skip_assign))
        if attributes.key?(reflection.foreign_store_key.to_s)
          v = attributes.delete(reflection.foreign_store_key.to_s)
          attributes[reflection.foreign_key.to_s] = v
        end
        record.send(:_assign_attributes, attributes) if attributes.any?
        set_inverse_instance(record)
      end

      private
        def creation_attributes
          return super if reflection.belongs_to?
          return super unless reflection.foreign_store?

          attributes = {}

          jsonb_store = reflection.foreign_store_attr
          attributes[jsonb_store] ||= {}
          attributes[jsonb_store][reflection.foreign_store_key] =
            owner[reflection.active_record_primary_key]

          attributes
        end
    end
  end
end
