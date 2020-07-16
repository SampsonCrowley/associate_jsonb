# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module AssociateJsonb
  module Associations
    module JoinDependency # :nodoc:
      private
        def table_aliases_for(parent, node)
          node.reflection.chain.map { |reflection|
            alias_tracker.aliased_table_for(
              reflection.table_name,
              table_alias_for(reflection, parent, reflection != node.reflection),
              reflection.klass.type_caster,
              reflection.klass.store_column_attribute_tracker
            )
          }
        end
    end
  end
end
