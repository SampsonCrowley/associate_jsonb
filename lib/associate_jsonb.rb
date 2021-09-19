# encoding: utf-8
# frozen_string_literal: true

require "active_record"
require "arel"
require "active_support/core_ext"
require "active_support/lazy_load_hooks"
require "active_support/concern"
require "pg"
require "active_record/connection_adapters/postgresql_adapter"
require "mutex_m"

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "postgresql" => "PostgreSQL",
  "supported_rails_version" => "SUPPORTED_RAILS_VERSION"
)
loader.collapse("#{__dir__}/associate_jsonb/connection_adapters/schema_definitions")
loader.setup # ready!

module AssociateJsonb
  mattr_accessor :jsonb_hash_types,  default: []
  mattr_accessor :jsonb_set_added,   default: [] # :nodoc:
  mattr_accessor :jsonb_set_removed, default: [] # :nodoc:
  mattr_accessor :jsonb_set_enabled, default: false
  mattr_accessor :jsonb_delete_nil,  default: false
  private_class_method :jsonb_hash_types=
  private_class_method :jsonb_set_enabled=

  def self.jsonb_oid_class # :nodoc:
    :default
  end
  private_class_method :jsonb_oid_class

  ##
  # Enables the use of `jsonb_nested_set` for hash updates
  #
  # if passed a class, or a list of classes, those classes will be added to
  # the enabled classes. if no argument is given, and the enabled class list is
  # empty, `ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb` is added
  # to the list of enabled classes
  def self.enable_jsonb_set(klass = nil, *classes)
    if klass.nil?
      add_hash_type jsonb_oid_class if jsonb_hash_types.empty?
    else
      add_hash_type(*Array(klass), *classes)
    end
    self.jsonb_set_enabled = true
  end

  ##
  # Disables the use of `jsonb_nested_set` for hash updates
  #
  # if passed a class, or a list of classes, those classes will be removed from
  # the list of enabled classes
  def self.disable_jsonb_set(klass = nil, *classes)
    remove_hash_type(*Array(klass), *classes) unless klass.nil?
    self.jsonb_set_enabled = false
  end

  ##
  # Add class(es) to the list of classes that are able to be upated when
  # `jsonb_set_enabled` is true
  def self.add_hash_type(*classes)
    self.jsonb_set_added |= classes.flatten
  end

  ##
  # Remove class(es) from the list of classes that are able to be upated when
  # `jsonb_set_enabled` is true
  def self.remove_hash_type(*classes)
    self.jsonb_set_removed |= classes.flatten
  end

  ##
  # Returns true if `jsonb_set_enabled` is true and the value is an enabled hash
  # type
  def self.merge_hash?(value)
    !!jsonb_set_enabled && is_hash?(value)
  end

  ##
  # Returns true if the given value is a descendant of any of the classes
  # in `jsonb_hash_types`
  def self.is_hash?(value)
    !!value && self.jsonb_hash_types.any? { |type| value.is_a?(type) }
  end
end

# rubocop:disable Metrics/BlockLength
ActiveSupport.on_load :active_record do
  loader.eager_load
  AssociateJsonb.module_eval do
    redefine_method = proc {|name, hide = false, &block|
      method(name).owner.remove_method name
      if block
        define_singleton_method(name, &block)
        private_class_method name if hide
      end
    }

    redefine_method.call(:jsonb_oid_class, true) do
      ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
    end

    redefine_method.call(:add_hash_type) do |*classes|
      self.jsonb_hash_types |= classes.flatten
    end

    redefine_method.call(:remove_hash_type) do |*classes|
      self.jsonb_hash_types -= classes.flatten
    end

    self.add_hash_type jsonb_set_added.map {|k| (k == :default) ? self.jsonb_oid_class : k}
    self.remove_hash_type jsonb_set_removed

    redefine_method.call(:jsonb_set_added)
    redefine_method.call(:jsonb_set_added=)
    redefine_method.call(:jsonb_set_removed)
    redefine_method.call(:jsonb_set_removed=)
    redefine_method = nil
  end


  ActiveRecord::Base.include AssociateJsonb::WithStoreAttribute
  ActiveRecord::Base.include AssociateJsonb::Associations
  ActiveRecord::Base.include AssociateJsonb::AttributeMethods
  ActiveRecord::Base.include AssociateJsonb::Persistence

  Arel::Nodes.include AssociateJsonb::ArelNodes

  Arel::Nodes::Binary.prepend(
    AssociateJsonb::ArelExtensions::Nodes::Binary
  )

  Arel::Nodes::TableAlias.prepend(
    AssociateJsonb::ArelExtensions::Nodes::TableAlias
  )

  Arel::Table.prepend(
    AssociateJsonb::ArelExtensions::Table
  )

  Arel::Visitors::PostgreSQL.prepend(
    AssociateJsonb::ArelExtensions::Visitors::PostgreSQL
  )

  Arel::Visitors::Visitor.singleton_class.prepend(
    AssociateJsonb::ArelExtensions::Visitors::Visitor
  )


  ActiveRecord::Associations::AliasTracker.prepend(
    AssociateJsonb::Associations::AliasTracker
  )

  ActiveRecord::Associations::Builder::BelongsTo.extend(
    AssociateJsonb::Associations::Builder::BelongsTo
  )

  ActiveRecord::Associations::Builder::HasOne.extend(
    AssociateJsonb::Associations::Builder::HasOne
  )

  ActiveRecord::Associations::Builder::HasMany.extend(
    AssociateJsonb::Associations::Builder::HasMany
  )

  ActiveRecord::Associations::Association.prepend(
    AssociateJsonb::Associations::Association
  )

  ActiveRecord::Associations::BelongsToAssociation.prepend(
    AssociateJsonb::Associations::BelongsToAssociation
  )

  ActiveRecord::Associations::HasManyAssociation.prepend(
    AssociateJsonb::Associations::HasManyAssociation
  )

  ActiveRecord::Associations::AssociationScope.prepend(
    AssociateJsonb::Associations::AssociationScope
  )

  ActiveRecord::Associations::Preloader::Association.prepend(
    AssociateJsonb::Associations::Preloader::Association
  )

  ActiveRecord::Associations::ForeignAssociation.prepend(
    AssociateJsonb::Associations::ForeignAssociation
  )

  %i[
    AlterTable
    ConstraintDefinition
    ReferenceDefinition
    SchemaCreation
    Table
    TableDefinition
  ].each do |m|
    includable = AssociateJsonb::ConnectionAdapters.const_get(m)
    including =
      begin
        ActiveRecord::ConnectionAdapters::PostgreSQL.const_get(m)
      rescue NameError
        ActiveRecord::ConnectionAdapters.const_get(m)
      end
    including.prepend includable
  rescue NameError
    ActiveRecord::ConnectionAdapters::PostgreSQL.const_set(m, includable)
  end

  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include(
    AssociateJsonb::ConnectionAdapters::SchemaStatements
  )


  ActiveRecord::Reflection::AbstractReflection.prepend AssociateJsonb::Reflection
  ActiveRecord::PredicateBuilder.prepend AssociateJsonb::PredicateBuilder
  ActiveRecord::Relation::WhereClause.prepend AssociateJsonb::Relation::WhereClause

  ActiveRecord::ConnectionAdapters::ReferenceDefinition.prepend(
    AssociateJsonb::ConnectionAdapters::ReferenceDefinition
  )
end
# rubocop:enable Metrics/BlockLength
