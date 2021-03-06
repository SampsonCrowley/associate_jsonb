# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Builder
      module HasMany #:nodoc:
        def valid_options(options)
          super + %i[ foreign_store foreign_store_key ]
        end
      end
    end
  end
end
