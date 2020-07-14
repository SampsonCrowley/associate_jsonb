# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module ReferenceDefinition #:nodoc:
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        name,
        store: false,
        **options
      )
        @store = store && store.to_sym

        super(name, **options)
      end
      # rubocop:enable Metrics/ParameterLists

      def add_to(table)
        return super unless store

        should_add_col = false
        if table.respond_to? :column_exists?
          should_add_col = !table.column_exists?(store)
        elsif table.respond_to? :columns
          should_add_col = table.columns.none? {|col| col.name.to_sym == store}
        end

        table.column(store, :jsonb, null: false, default: {}) if should_add_col

        return unless index

        # should_add_idx = false
        # if table.respond_to? :index_exists?
        #   should_add_idx = !table.index_exists?([ store ], using: :gin)
        # elsif table.respond_to? :indexes
        #   should_add_idx = table.indexes.none? do |idx, opts|
        #     (idx == [ store ]) \
        #     && (opts == { using: :gin })
        #   end
        # end
        #
        # table.index([ store ], using: :gin) if should_add_idx

        column_names.each do |column_name|
          table.index(
            "CAST (\"#{store}\"->'#{column_name}' AS #{@type || :bigint})",
            using: :btree,
            name: "index_#{table.name}_on_#{store}_#{column_name}"
          )

          table.index(
            "(#{store}->>'#{column_name}')",
            using: :btree,
            name: "index_#{table.name}_on_#{store}_#{column_name}_text"
          )
        end
      end

      protected

      attr_reader :store
    end
  end
end
