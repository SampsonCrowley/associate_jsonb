# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module AssociateJsonb
  module Associations
    module AliasTracker # :nodoc:
      def aliased_table_for(table_name, aliased_name, type_caster, store_tracker = nil)
        super(table_name, aliased_name, type_caster).with_store_tracker(store_tracker)
      end
    end
  end
end
