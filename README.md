# associate_jsonb

[![Gem Version](https://badge.fury.io/rb/associate_jsonb.svg)](https://badge.fury.io/rb/associate_jsonb)

#### Easy PostgreSQL JSONB extensions
**including:**

- Basic ActiveRecord Associations using PostgreSQL JSONB columns, with built-in accessors and column indexes
- Thread-Safe JSONB updates (well, as safe as they can be) using a custom nested version of `jsonb_set` (`jsonb_nested_set`)

**Requirements:**

- PostgreSQL (>= 12)
- Rails 6.0.3.2

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'associate_jsonb'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Jsonb Associations

#### One-to-One and One-to-Many associations

To set up your jsonb column, you can use the built in `add_reference`/`table.references` function. This will only add a new store column if it doesn't already exist

```bash
rails g migration add_foreign_key_store_to_my_table
```
```ruby
class AddForeignKeyStoreToMyTable < ActiveRecord::Migration[6.0]
  def change
    add_reference :my_table, :user, store: :extra # => store created
    add_reference :my_table, :label, store: :extra, null: false # => store already exists, NOT NULL check constraint added to `store->'label_id'`
    # NOTE: you can also use a `change_table(:my_table) block`
  end
end
```

and

```ruby
class CreateMyTable < ActiveRecord::Migration[6.0]
  def change
    create_table(:my_table) do |t|
      t.references :user, store: :extra
      t.references :label, store: :extra, null: false
    end
  end
end
```

If you add the `jsonb_foreign_key` function to your database, you can also create a foreign_key **check** constraint by using the same built-in `:foreign_key` option used in normal reference definitions.

**NOTE**: true foreign key references are not possible with jsonb attributes. This will instead create a CHECK constraint that looks for the referenced column using an `EXISTS` statement

```bash
rails g migration add_jsonb_foreign_key_function
```
```ruby
class AddJsonbForeignKeyFunction < ActiveRecord::Migration[6.0]
  def up
    add_jsonb_foreign_key_function
  end
end
```
```ruby
class CreateMyTable < ActiveRecord::Migration[6.0]
  def change
    create_table(:my_table) do |t|
      t.references :user, store: :extra, foreign_key: true, null: false
    end
  end
end
```
```ruby
class CreateMyTable < ActiveRecord::Migration[6.0]
  def change
    create_table(:my_table) do |t|
      t.references :person, store: :extra, foreign_key: { to_table: :users }, null: false
    end
  end
end
```


You can store all foreign keys of your model in one JSONB column, without having to create multiple columns:

```ruby
class Profile < ActiveRecord::Base
  # Setting additional :store option on :belongs_to association
  # enables saving of foreign ids in :extra JSONB column
  belongs_to :user, store: :extra
end

class SocialProfile < ActiveRecord::Base
  belongs_to :user, store: :extra
end

class User < ActiveRecord::Base
  # Parent model association needs to specify :foreign_store
  # for associations with JSONB storage
  has_one :profile, foreign_store: :extra
  has_many :social_profiles, foreign_store: :extra
end
```

### Many-to-Many associations

Due to the ease of getting out-of-sync, and the complexity needed to build it, HABTM relation functionality has not been implemented through JSONB

### jsonb_set based hash updates

When enabled, *only* keys present in the updated hash and with values changed in memory will be updated.
To completely delete a `key/value` pair from an enabled attribute, set the key's value to `nil`.

e.g.

```ruby
# given: instance#data == { "key_1"=>1,
#                           "key_2"=>2,
#                           "key_3"=> { "key_4"=>7,
#                                       "key_5"=>8,
#                                       "key_6"=>9 } }

instance.update({ key_1: "asdf", a: 1, key_2: nil, key_3: { key_5: nil }})

# instance#data => { "key_1"=>"asdf",
#                    "a"=>"asdf",
#                    "key_3"=> { "key_4"=>7,
#                                "key_6"=>9 } }
```

#### enabling/adding attribute types

first, create the sql function

```bash
rails g migration add_jsonb_nested_set_function
```
```ruby
class AddJsonbNestedSetFunction < ActiveRecord::Migration[6.0]
  def up
    add_jsonb_nested_set_function
  end
end
```

then in an initializer, enable key based updates:

```ruby
# config/initializers/associate_jsonb.rb
AssociateJsonb.enable_jsonb_set
```

- Key based updates rely on inheritance for allowed attribute types. Any attributes that respond true to `attr_type.is_a?(GivenClass)` for any enabled type classes will use `jsonb_nested_set`

- To add classes to the enabled list, pass them as arguments to `AssociateJsonb.add_hash_type(*klasses)`. Any arguments passed to `AssociateJsonb.enable_jsonb_set` are forwarded to `AssociateJsonb.add_hash_type`

- By default, calling `AssociateJsonb.enable_jsonb_set(*klasses)` without arguments, and no classes previously added, adds `ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb` to the allowed classes list

#### disabling/removing attribute types

- by default `jsonb_nested_set` updates are disabled.

- if you've enabled them and need to disable, use: `AssociateJsonb.disable_jsonb_set`

- To remove a class from the allowed list while leaving nested set updates enabled, use `AssociateJsonb.remove_hash_type(*klasses)`.
Any arguments passed to `AssociateJsonb.disable_jsonb_set` are forwarded to `AssociateJsonb.remove_hash_type`

### Automatically delete nil value hash keys

When jsonb_set updates are disabled, jsonb columns are replaced with the current document (i.e. default rails behavior)

You are also given the option to automatically clear nil/null values from the hash automatically when jsonb_set is disabled

in an initializer:

```ruby
# config/initializers/associate_jsonb.rb
AssociateJsonb.jsonb_delete_nil = true
```

Rules for classes to which this applies are the same as for `jsonb_nested_set`; add and remove classes through `AssociateJsonb.(add|remove)_hash_type(*klasses)`

## Developing

To setup development environment, run:

```bash
$ bin/setup
```

To run specs:

```bash
$ bundle exec rspec
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
