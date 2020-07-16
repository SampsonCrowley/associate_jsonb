# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class Attribute
        attr_reader :relation, :name, :delegated

        def initialize(relation, name, delegated)
          @relation = relation,
          @name = name
          @delegated = delegated
        end

        def lower
          relation.lower self
        end

        def type_cast_for_database(value)
          relation.type_cast_for_database(name, value)
        end

        def able_to_type_cast?
          relation.able_to_type_cast?
        end

        def respond_to_missing?(mthd, include_private = false)
          delegated.respond_to?(mthd, include_private)
        end

        def method_missing(mthd, *args, **opts, &block)
          delegated.public_send(mthd, *args, **opts, &block)
        end
      end
    end
  end
end
