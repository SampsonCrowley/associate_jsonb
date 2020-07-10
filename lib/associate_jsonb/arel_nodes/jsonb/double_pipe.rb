# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelNodes
    module Jsonb
      class DoublePipe < AssociateJsonb::ArelNodes::BindableOperator #:nodoc:
        def operator
          '||'
        end
      end
    end
  end
end
