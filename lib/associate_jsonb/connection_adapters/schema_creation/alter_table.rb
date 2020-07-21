# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module SchemaCreation
      class AlterTable # :nodoc:
        attr_reader :constraint_adds
        attr_reader :constraint_drops

        def initialize(td)
          super
          @constraint_adds = []
          @constraint_drops = []
        end


        def add_foreign_key(to_table, options)
          @foreign_key_adds << ForeignKeyDefinition.new(name, to_table, options)
        end

        def drop_foreign_key(name)
          @foreign_key_drops << name
        end

        def add_constraint(options)
          @foreign_key_adds << ConstraintDefinition.new(name, options)
        end

        def drop_constraint(options)
          @constraint_drops << ConstraintDefinition.new(name, options)
        end
      end
    end
  end
end
