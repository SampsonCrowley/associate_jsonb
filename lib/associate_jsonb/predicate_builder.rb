# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module PredicateBuilder # :nodoc:
    def build_bind_attribute(column_name, value)
      if value.respond_to?(:value_before_type_cast)
        attr = ActiveRecord::Relation::QueryAttribute.new(column_name.to_s, value.value_before_type_cast, table.type(column_name), value)
      else
        attr = ActiveRecord::Relation::QueryAttribute.new(column_name.to_s, value, table.type(column_name))
      end
      Arel::Nodes::BindParam.new(attr)
    end
  end
end
