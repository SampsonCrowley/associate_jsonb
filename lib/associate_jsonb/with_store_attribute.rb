# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module WithStoreAttribute
    extend ActiveSupport::Concern

    class StoreColumnAttributeTracker < Module #:nodoc:
      include Mutex_m

      def names_list
        @names_list ||= {}
      end

      def add_name(name, store, key)
        @names_list ||= {}
        @names_list[name.to_s.freeze] = { store: store, key: key }
      end

      def has_name?(name)
        names_list.key? name.to_s
      end
    end

    included do
      instance_eval <<-CODE, __FILE__, __LINE__ + 1
        initialize_store_column_attribute_tracker

        after_initialize &set_store_column_attribute_values_on_init
        after_commit &set_store_column_attribute_values_on_init
      CODE
    end

    module ClassMethods
      def inherited(child)
        child.initialize_store_column_attribute_tracker
        super
      end

      def initialize_store_column_attribute_tracker
        @store_column_attribute_tracker = const_set(:StoreColumnAttributeTracker, StoreColumnAttributeTracker.new)
        private_constant :StoreColumnAttributeTracker

        store_column_attribute_tracker
      end

      def store_column_attribute_tracker
        @store_column_attribute_tracker ||= initialize_store_column_attribute_tracker
      end

      def store_column_attribute_names
        store_column_attribute_tracker.synchronize do
          current_store_col_names = {}
          current_store_col_names.merge!(super) if defined? super
          current_store_col_names.merge!(store_column_attribute_tracker.names_list)
        end
      end

      def add_store_column_attribute_name(name, store, key)
        store_column_attribute_tracker.synchronize do
          store_column_attribute_tracker.add_name(name, store, key)
        end
      end

      def is_store_column_attribute?(name)
        store_column_attribute_tracker.synchronize do
          store_column_attribute_tracker.has_name?(name)
        end
      end

      def set_store_column_attribute_values_on_init
        lambda do
          self.class.store_column_attribute_names.each do |attr, opts|
            _write_attribute(attr, _read_attribute(opts[:store])[opts[:key]])
            clear_attribute_change(attr) if persisted?
          end
        rescue
          nil
        end
      end

      def data_column_attribute(*args, **opts)
        store_column_attribute :data, *args, **opts
      end

      def store_column_attribute(store, attr, *opts, key: nil, **attribute_opts)
        store = store.to_sym
        attr = attr.to_sym
        key ||= attr
        key = key.to_s
        array = attribute_opts[:array]
        attribute attr, *opts, **attribute_opts

        instance_eval <<-CODE, __FILE__, __LINE__ + 1
          add_store_column_attribute_name("#{attr}", :#{store}, "#{key}")
        CODE

        include WithStoreAttribute::InstanceMethodsOnActivation.new(self, store, attr, key, array)
      end
    end

    class InstanceMethodsOnActivation < Module
      def initialize(mixin, store, attribute, key, is_array)
        is_array = !!(is_array && attribute.to_s =~ /_ids$/)
        on_attr_change =
           is_array \
            ? "write_attribute(:#{attribute}, Array(given))" \
            : "super(given)"
        if is_array
          mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{attribute}
              _read_attribute(:#{attribute}) || []
            end
          CODE
        end

        mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{store}=(given)
            given = super((given || {}).with_indifferent_access)
            write_attribute(:#{attribute}, given["#{key}"])
            given["#{key}"] = #{attribute} unless #{attribute}.nil?
            super(given)
          end

          def #{attribute}=(given)
            #{on_attr_change}
            value = #{store}["#{key}"] = #{attribute}
            #{store}.delete("#{key}") if value.nil?
            _write_attribute(:#{store}, #{store})
            value
          end
        CODE
      end
    end

    def is_store_column_attribute?(name)
      self.class.is_store_column_attribute?(name)
    end

    def [](k)
      if is_store_column_attribute?(k)
        self.public_send(k)
      else
        super
      end
    end

    def []=(k, v)
      if is_store_column_attribute?(k)
        self.public_send(:"#{k}=", v)
      else
        super
      end
    end
  end
end
