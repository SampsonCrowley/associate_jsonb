# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Builder
      module BelongsTo #:nodoc:
        # Maybe convert to builder callbacks here in next iteration
        # def define_callbacks(model, reflection)
        #   super
        #   add_after_jsonb_initialize_callbacks(model, reflection) if reflection.jsonb_store?
        #   add_after_foreign_store_initialize_callbacks(model, reflection) if reflection.foreign_store?
        # end
        #
        # def add_after_jsonb_initialize_callbacks(model, reflection)
        #   model.after_initialize lambda {|record|
        #     association = association(reflection.name)
        #     p model, reflection.join_primary_key, reflection.join_foreign_key, reflection.options
        #     p record.attributes
        #     # record.attributes._write_attribute()
        #   }
        # end
        #
        # def add_after_foreign_store_initialize_callbacks(model, reflection)
        #   model.after_initialize lambda {|record|
        #     association = association(reflection.name)
        #     # record.attributes._write_attribute()
        #   }
        # end

        def valid_options(options)
          super + %i[ store store_key ]
        end

        def define_accessors(mixin, reflection)
          if reflection.options.key?(:store)
            add_association_accessor_methods(mixin, reflection)
          end

          super
        end

        def add_association_accessor_methods(mixin, reflection)
          foreign_key = reflection.join_foreign_key.to_s
          key = (reflection.jsonb_store_key || foreign_key).to_s
          store = reflection.jsonb_store_attr

          mixin.instance_eval <<~CODE, __FILE__, __LINE__ + 1
            if attribute_names.include?(foreign_key)
              raise AssociateJsonb::Associations::
                      ConflictingAssociation,
                        "Association with foreign key :#{foreign_key} already "\
                        "exists on #{reflection.active_record.name}"
            end
          CODE

          opts = {}
          foreign_type = :integer
          sql_type = "numeric"
          begin
            primary_key = reflection.join_primary_key.to_s
            primary_column = reflection.klass.columns_hash[primary_key]

            if primary_column
              foreign_type = primary_column.type
              sql_data = primary_column.sql_type_metadata.as_json
              sql_type = sql_data["sql_type"]
              %i[ limit precision scale ].each do |k|
                opts[k] = sql_data[k.to_s] if sql_data[k.to_s]
              end
            end
          rescue
            opts = { limit: 8 }
            foreign_type = :integer
          end

          mixin.instance_eval <<~CODE, __FILE__, __LINE__ + 1
            store_column_attribute(:#{store}, :#{foreign_key}, foreign_type, sql_type: sql_type, key: "#{key}", **opts)
          CODE
        end
      end
    end
  end
end
