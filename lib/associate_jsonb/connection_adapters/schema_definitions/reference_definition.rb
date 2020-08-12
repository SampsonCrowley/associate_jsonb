# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module ConnectionAdapters
    module ReferenceDefinition
      ForeignKeyDefinition = ActiveRecord::ConnectionAdapters::ForeignKeyDefinition
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        name,
        store: false,
        store_key: false,
        **options
      )
        @store = store && store.to_sym
        @store_key = store_key && store_key.to_s unless options[:polymorphic]
        @nullable = options[:null] != false

        super(name, **options)
      end
      # rubocop:enable Metrics/ParameterLists

      def column_name
        store_key || super
      end

      def add_to(table)
        return super unless store

        should_add_col = false
        if table.respond_to? :column_exists?
          should_add_col = !table.column_exists?(store)
        elsif table.respond_to? :columns
          should_add_col = table.columns.none? {|col| col.name.to_sym == store}
        end

        if should_add_col
          opts = { null: false, default: {} }
          table.column(store, :jsonb, **opts)
        end

        if foreign_key && column_names.length == 1
          fk = ForeignKeyDefinition.new(table.name, foreign_table_name, foreign_key_options)
          columns.each do |col_name, type, options|
            options ||= {}
            value = <<-SQL.squish
              jsonb_foreign_key(
                '#{fk.to_table}'::text,
                '#{fk.primary_key}'::text,
                #{store}::jsonb,
                '#{col_name}'::text,
                '#{type}'::text,
                #{nullable}
              )
            SQL
            table.constraint(
              name: "#{table.name}_#{col_name}_foreign_key",
              value: value,
              not_valid: true,
              deferrable: true
            )
          end
        elsif !nullable
          columns.each do |col_name, *|
            value = <<-SQL.squish
              #{store}->>'#{col_name}' IS NOT NULL
              AND
              #{store}->>'#{col_name}' <> ''
            SQL
            table.constraint(
              name: "#{table.name}_#{col_name}_not_null",
              value: value,
              not_valid: false,
              deferrable: true
            )
          end
        end

        return unless index

        columns.each do |col_name, type, *|
          type = :text if type == :string
          table.index(
            "CAST (\"#{store}\"->>'#{col_name}' AS #{type || :bigint})",
            using: :btree,
            name: "index_#{table.name}_on_#{store}_#{col_name}"
          )

          table.index(
            "(\"#{store}\"->>'#{col_name}')",
            using: :btree,
            name: "index_#{table.name}_on_#{store}_#{col_name}_text"
          )
        end
      end

      protected

      attr_reader :store, :store_key, :nullable
    end
  end
end
