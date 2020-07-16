# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ArelExtensions
    module Visitors
      module Visitor
        def dispatch_cache
          @dispatch_cache ||= Hash.new do |hash, klass|
            hash[klass] =
              "visit_#{(klass.name || '').
                sub("AssociateJsonb::ArelNodes::SqlCasted", "Arel::Nodes::").
                gsub('::', '_')}"
          end
        end
      end
    end
  end
end
