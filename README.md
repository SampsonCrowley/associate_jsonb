# associate_jsonb

[![Gem Version](https://badge.fury.io/rb/associate_jsonb.svg)](https://badge.fury.io/rb/associate_jsonb)

#### PostgreSQL JSONB extensions including:
  - Basic ActiveRecord Associations using PostgreSQL JSONB columns, with built-in accessors and column indexes
  - Thread-Safe JSONB updates (well, as safe as they can be) using a custom nested version of `jsonb_set` (`jsonb_nested_set`)

**Requirements:**

- PostgreSQL (>= 12)
- Rails 6.0.3.2

## Usage

### Jsonb Associations


### jsonb_set based hash updates

When enabled, *only* keys present in the updated hash and with values changed in memory will be updated.
To completely delete a key, value pair from an enabled attribute, set the key's value to `nil`.

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
class CreateState < ActiveRecord::Migration[6.0]
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

Key based updates rely on inheritance for allowed attribute types. Any attributes that respond true to `attr_type.is_a?(GivenClass)` for any enabled type classes will use `jsonb_nested_set`

To add classes to the enabled list, pass them as arguments to `AssociateJsonb.add_hash_type(*klasses)`. Any arguments passed to `AssociateJsonb.enable_jsonb_set` are forwarded to `AssociateJsonb.add_hash_type`

By default, calling `AssociateJsonb.enable_jsonb_set(*klasses)` without arguments, and no classes previously added, adds `ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb` to the allowed classes list

#### disabling/removing attribute types
by default `jsonb_nested_set` updates are disabled.

if you've enabled them and need to disable, use: `AssociateJsonb.disable_jsonb_set`

To remove a class from the allowed list while leaving nested set updates enabled, use `AssociateJsonb.remove_hash_type(*klasses)`.
Any arguments passed to `AssociateJsonb.disable_jsonb_set` are forwarded to `AssociateJsonb.remove_hash_type`

### Automatically delete nil value hash keys

When jsonb_set updates are disabled, jsonb columns are replaced with the current document (i.e. default rails behavior)

You are also given the option to automatically clear nil/null values from the hash automatically

in an initializer, enable stripping nil values:
```ruby
# config/initializers/associate_jsonb.rb
AssociateJsonb.jsonb_delete_nil = true
```

Rules for classes to with this applies are the same as for `jsonb_nested_set`; add and remove classes through `AssociateJsonb.(add|remove)_hash_type(*klasses)`

<!-- This gem was created as a solution to this [task](http://cultofmartians.com/tasks/active-record-jsonb-associations.html) from [EvilMartians](http://evilmartians.com).

**Requirements:**

- PostgreSQL (>= 9.6)

## Usage

### One-to-one and One-to-many associations

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

Foreign keys for association on one model have to be unique, even if they use different store column.

You can also use `add_references` in your migration to add JSONB column and index for it (if `index: true` option is set):

```ruby
add_reference :profiles, :users, store: :extra, index: true
```

### Many-to-many associations

Due to the ease of getting out-of-sync, and the complexity needed to build it, HABTM relation functionality has not been implemented through JSONB

#### Performance

Compared to regular associations, fetching models associated via JSONB column has no drops in performance.

Getting the count of connected records is ~35% faster with associations via JSONB (tested on associations with up to 10 000 connections).

Adding new connections is slightly faster with JSONB, for scopes up to 500 records connected to another record (total count of records in the table does not matter that much. If you have more then ~500 records connected to one record on average, and you want to add new records to the scope, JSONB associations will be slower then traditional:

<img src="https://github.com/lebedev-yury/associate_jsonb/blob/master/doc/images/adding-associations.png?raw=true | width=500" alt="JSONB HAMTB is slower on adding associations" width="600">

On the other hand, unassociating models from a big amount of associated models if faster with JSONB HABTM as the associations count grows:

<img src="https://github.com/lebedev-yury/associate_jsonb/blob/master/doc/images/deleting-associations.png?raw=true | width=500" alt="JSONB HAMTB is faster on removing associations" width="600">

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'associate_jsonb'
```

And then execute:

```bash
$ bundle install
```

## Developing

To setup development environment, just run:

```bash
$ bin/setup
```

To run specs:

```bash
$ bundle exec rspec
```

To run benchmarks (that will take a while):

```bash
$ bundle exec rake benchmarks:habtm
``` -->

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
