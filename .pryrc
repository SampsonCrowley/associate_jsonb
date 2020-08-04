og_print = Pry.config.print
Pry.config.history_file = "#{__dir__}/.pry_history"
(Pry.config.history.file = "#{__dir__}/.pry_history") rescue nil

Pry.config.print = proc do |output, value, *args|
  begin
    if (ActiveRecord::Base === value) ||
      (ActiveRecord::Relation === value)
      is_relation = ActiveRecord::Relation === value
      base = (is_relation ? nil : value)
      i = 0
      idx = {'   #' => ->(*args) { "   #{i += 1}" }}
      keys =
        [
          idx,
          *(
            catch(:attribute_names) do
              unless base
                throw :attribute_names, value.select_values.map(&:to_s) if value.respond_to?(:select_values) && value.select_values.present?
                throw :attribute_names, value.klass.default_print if value.klass.respond_to?(:default_print)
                throw :attribute_names, value.klass.column_names
              end
              throw :attribute_names, base.attribute_names if (base.class.attribute_names - base.attribute_names).present?
              throw :attribute_names, base.class.default_print if base.class.respond_to?(:default_print)
              throw :attribute_names, base.attribute_names
            end
          )
        ]

      puts "\n"
      if is_relation
        sz = 0
        begin
          tp value, keys if value.size > 0
          sz = value.size
        rescue
          tp value, keys if value.size.size > 0
          sz = value.size.size
        end
        puts "\n   #{sz} rows returned" if is_relation
      else
        tp value, keys
      end
      puts "\n"
    else
      og_print.call output, value, *args
    end
  rescue
    puts $!.message
    puts $!.backtrace
    og_print.call output, value, *args
  end
end
