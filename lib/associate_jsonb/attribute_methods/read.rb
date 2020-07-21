# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module AttributeMethods
    module Read
      extend ActiveSupport::Concern

      def _fetch_attribute(attr_name, &block) # :nodoc
        sync_with_transaction_state if @transaction_state&.finalized?
        @attributes.fetch(attr_name.to_s, &block)
      end
    end
  end
end
