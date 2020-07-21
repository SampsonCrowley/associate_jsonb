# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module AttributeMethods
    extend ActiveSupport::Concern

    included do
      include Read
    end

    private
      def attributes_with_info(attribute_names)
        attribute_names.each_with_object({}) do |name, attrs|
          attrs[name] = _fetch_attribute(name)
        end
      end
  end
end
