# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Associations
    module Builder
      module HasMany #:nodoc:
        def valid_options(options)
          super + %i[ store store_key foreign_store foreign_store_attr ]
        end

        def define_accessors(mixin, reflection)
          if reflection.jsonb_store?
            reflection.options[:primary_key] ||= "#{reflection.name.to_s.singularize}_ids"
            reflection.options[:foreign_key] ||= reflection.klass.primary_key
            add_association_accessor_methods(mixin, reflection)
          end

          super
        end

        # def add_association_accessor_methods(mixin, reflection)
        #   mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        #     def [](key)
        #       key = key.to_s
        #       if key.ends_with?('_ids') &&
        #           #{reflection.options[:store]}.keys.include?(key)
        #         #{reflection.options[:store]}[key]
        #       else
        #         super
        #       end
        #     end
        #   CODE
        # end

        def add_association_accessor_methods(mixin, reflection)
          foreign_key = "#{reflection.name.to_s.singularize}_ids"

          mixin.instance_eval <<-CODE, __FILE__, __LINE__ + 1
            if attribute_names.include?(foreign_key)
              raise AssociateJsonb::Associations::
                      ConflictingAssociation,
                        "Association with foreign key :#{foreign_key} already "\
                        "exists on #{reflection.active_record.name}"
            end
          CODE



          opts         = {}
          key          = (reflection.habtm_store_key || foreign_key).to_s
          store        = reflection.jsonb_store_attr
          foreign_type = :integer

          begin
            primary_key = (reflection.klass.primary_key || "id").to_s
            primary_column = reflection.klass.columns.find {|col| col.name == primary_key }

            if primary_column
              foreign_type = primary_column.type
              sql_data = primary_column.sql_type_metadata.as_json
              %i[ limit precision scale ].each do |k|
                opts[k] = sql_data[k.to_s] if sql_data[k.to_s]
              end
            end
          rescue
            opts = { limit: 8 }
            foreign_type = :integer
          end


          mixin.instance_eval <<-CODE, __FILE__, __LINE__ + 1
            store_column_attribute(:#{store}, :#{foreign_key}, :#{foreign_type}, array: true, key: "#{key}", **opts)
          CODE
        end
      end
    end
  end
end
