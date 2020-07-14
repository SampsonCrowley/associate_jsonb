# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class DashDoubleArrow < AssociateJsonb::ArelNodes::Jsonb::Operator #:nodoc:
        def operator
          '->>'
        end
      end
    end
  end
end
