module AssociateJsonb
  module ArelExtensions
    module Visitors
      module PostgreSQL
        private
          def collect_hash_changes(original, updated, nesting = nil)
            keys = original.keys.map(&:to_s)
            updated_keys = updated.keys.map(&:to_s)
            keys |= updated_keys
            original = original.with_indifferent_access
            updated = updated.with_indifferent_access
            added = []
            deleted = []
            finished = {}
            keys.each do |k|
              if original[k].is_a?(Hash) && updated[k].is_a?(Hash)
                finished[k], a, d = collect_hash_changes(original[k], updated[k], nesting ? "#{nesting},#{k}" : k)
                added |= a
                deleted |= d
              else
                if updated[k].nil?
                  deleted << (nesting ? "{#{nesting},#{k}}" : "{#{k}}") if updated_keys.include?(k)
                elsif original[k] != updated[k]
                  finished[k] = updated[k]
                  added << [(nesting ? "{#{nesting},#{k}}" : "{#{k}}"), updated[k]]
                end
              end
            end
            [ finished, added, deleted ]
          end

          def is_hash_update?(o, collector)
            collector &&
              Array(collector.value).any? {|v| v.is_a?(String) && (v =~ /UPDATE/) } &&
              AssociateJsonb.safe_hash_classes.any? {|t| o.value.type.is_a?(t) }
          rescue
            false
          end

          def visit_Arel_Nodes_BindParam(o, collector)
            if is_hash_update?(o, collector)
              value = o.value

              changes, additions, deletions =
                collect_hash_changes(
                  value.original_value.presence || {},
                  value.value.presence || {}
                )

              json = +"COALESCE(#{quote_column_name(o.value.name)}, '{}'::jsonb)"

              deletions.each do |del|
                json = +"(#{json} #- '#{del}')"
              end

              additions.each do |add, value|
                collector.add_bind(o.value.with_value_from_user(value)) do |i|
                  json = +"jsonb_set(#{json},'#{add}', $#{i}, true)"
                  ''
                end
              end

              collector << json

              collector
            else
              collector.add_bind(o.value) { |i| "$#{i}" }
            end
          end
      end
    end
  end
end
