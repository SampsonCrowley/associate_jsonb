# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class AtArrow < AssociateJsonb::ArelNodes::Jsonb::BindableOperator
        def operator
          '@>'
        end
      end
    end
  end
end
