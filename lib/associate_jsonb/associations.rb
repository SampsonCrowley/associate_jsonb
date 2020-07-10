# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    extend ActiveSupport::Concern

    class_methods do
      # rubocop:disable Naming/PredicateName
      def has_and_belongs_to_many(name, scope = nil, **options, &extension)
        return super unless options.key?(:store)
        has_many(name, scope, **options, &extension)
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end
