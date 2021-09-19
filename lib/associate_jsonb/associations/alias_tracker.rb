# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module AssociateJsonb
  module Associations
    module AliasTracker # :nodoc:
      def aliased_table_for(arel_table, table_name = nil, store_tracker: nil)
        super(arel_table, table_name).with_store_tracker(store_tracker)
      end
    end
  end
end
