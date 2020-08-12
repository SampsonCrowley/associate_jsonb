require "yaml"
require "pg"

db_config = YAML.load_file(
  File.expand_path("../../config/database.yml", __FILE__)
).fetch("pg")

db_config = {
  adapter: "postgresql",
  database: "associate_jsonb_gem_test",
  username: db_config.fetch("username"),
  min_messages: "warning"
}.with_indifferent_access

ActiveRecord::Base.establish_connection(db_config)

ActiveRecord::Migration.verbose = false

# rubocop:disable Metrics/BlockLength
ActiveRecord::Schema.define do
  enable_extension :pgcrypto

  add_jsonb_foreign_key_function
  add_jsonb_nested_set_function

  create_table :users, force: true do |t|
    t.jsonb :extra, null: false, default: {}
    t.jsonb :sub_data, null: false, default: {}
    t.timestamps null: false
  end

  create_table :uuids, id: :uuid, force: true do |t|
    t.timestamps null: false
  end

  create_table :goods_suppliers, force: true do |t|
    t.timestamps null: false
  end

  create_table :profiles, force: true do |t|
    t.belongs_to :user, null: false
    t.timestamps null: false
  end

  create_table :accounts, force: true do |t|
    t.references :user, store: :extra, index: true
    t.references :supplier, store: :extra, index: true
    t.timestamps null: false
  end

  create_table :photos, force: true do |t|
    t.belongs_to :user
    t.timestamps null: false
  end

  create_table :invoice_photos, force: true do |t|
    t.references :supplier, store: :extra, index: true
    t.timestamps null: false
  end

  create_table :social_profiles, force: true do |t|
    t.references :user, store: :extra, index: true
    t.timestamps null: false
  end

  create_table :labels, force: true do |t|
    t.references :user, store: :extra, store_key: 'label_user', index: true, foreign_key: true
    t.references :uuid, store: :extra, store_key: 'uuid', index: true, type: :uuid
    t.timestamps null: false
  end

  create_table :fk_tests, force: true do |t|
    t.references :user, store: :data, index: false, foreign_key: true, null: false
  end

  create_table :null_tests, force: true do |t|
    t.references :user, store: :data, index: false, null: false
  end

  create_table :groups, force: true do |t|
    t.timestamps null: false
  end

  create_table :groups_users, force: true do |t|
    t.belongs_to :user
    t.belongs_to :group
  end
end
# rubocop:enable Metrics/BlockLength

original_schema = ENV["SCHEMA"]

dump_new_schema = ->(ext, type = nil) do
  ENV["SCHEMA"] = File.expand_path("../../config/schema.#{ext}", __FILE__)
  ActiveRecord::Tasks::DatabaseTasks.dump_schema(db_config, type || ext)
ensure
  ENV["SCHEMA"] = original_schema
end

dump_new_schema.call(:sql)
dump_new_schema.call("rb", :ruby)
