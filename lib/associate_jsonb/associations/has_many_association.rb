# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module HasManyAssociation #:nodoc:
      # rubocop:disable Metrics/AbcSize
      def delete_count(method, scope)
        return super if method == :delete_all
        return super unless store = reflection.foreign_store_attr

        scope.update_all("#{store} = #{store} #- '{#{reflection.foreign_store_key}}'")
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
