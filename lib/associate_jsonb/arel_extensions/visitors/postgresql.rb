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
              if updated[k].is_a?(Hash)
                finished[k], a, d = collect_hash_changes(original[k].is_a?(Hash) ? original[k] : {}, updated[k], nesting ? "#{nesting},#{k}" : k)
                a = [[(nesting ? "{#{nesting},#{k}}" : "{#{k}}"), {}]] if original[k].nil? && a.blank?
                added |= a
                deleted |= d
              elsif updated[k].nil?
                  deleted << (nesting ? "{#{nesting},#{k}}" : "{#{k}}") if updated_keys.include?(k)
              elsif original[k] != updated[k]
                finished[k] = updated[k]
                added << [(nesting ? "{#{nesting},#{k}}" : "{#{k}}"), updated[k]]
              end
            end
            [ finished, added, deleted ]
          end

          def is_hash?(type)
            AssociateJsonb.is_hash? type
          end

          def is_update?(collector)
            collector &&
              Array(collector.value).any? {|v| v.is_a?(String) && (v =~ /UPDATE/) }
          rescue
            false
          end

          def is_insert?(collector)
            collector &&
              Array(collector.value).any? {|v| v.is_a?(String) && (v =~ /INSERT INTO/) }
          rescue
            false
          end

          def visit_BindHashChanges(t, collector)
            changes, additions, deletions =
              collect_hash_changes(
                t.original_value.presence || {},
                t.value.presence || {}
              )

            base_json = +"COALESCE(#{quote_column_name(t.name)}, '{}'::jsonb)"
            json = base_json

            deletions.each do |del|
              json = +"(#{json} #- '#{del}')"
            end

            coalesced_paths = []
            additions.sort.each do |add, value|
              collector.add_bind(t.with_value_from_user(value)) do |i|
                json = +"jsonb_nested_set(#{json},'#{add}', COALESCE($#{i}, '{}'::jsonb))"
                ''
              end
            end

            collector << json
          end

          def visit_Arel_Nodes_BindParam(o, collector)
            catch(:nodes_bound) do
              if AssociateJsonb.jsonb_set_enabled
                catch(:not_hashable) do
                  if is_hash?(o.value.type)
                    if is_update?(collector)
                      visit_BindHashChanges(o.value, collector)

                      throw :nodes_bound, collector
                    elsif is_insert?(collector)
                      value = o.value

                      value, _, _ =
                        collect_hash_changes(
                          {},
                          value.value.presence || {}
                        )
                      throw :nodes_bound, collector.add_bind(o.value.with_cast_value(value)) { |i| "$#{i}"}
                    else
                      throw :not_hashable
                    end
                  else
                    throw :not_hashable
                  end
                end
              elsif AssociateJsonb.jsonb_delete_nil && is_hash?(o.value.type)
                value, _, _ =
                  collect_hash_changes(
                    {},
                    o.value.value.presence || {}
                  )
                throw :nodes_bound, collector.add_bind(o.value.with_cast_value(value)) { |i| "$#{i}" }
              end
              throw :nodes_bound, collector.add_bind(o.value) { |i| "$#{i}" }
            end
          end
      end
    end
  end
end
