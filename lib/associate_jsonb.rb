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
  mattr_accessor :jsonb_hash_types, default: []
  mattr_accessor :jsonb_set_removed, default: []
  mattr_accessor :jsonb_set_enabled, default: false
  mattr_accessor :jsonb_delete_nil, default: false
  private_class_method :jsonb_hash_types=
  private_class_method :jsonb_set_enabled=

  def self.enable_jsonb_set(klass = nil, *classes)
    add_hash_type(*Array(klass), *classes) unless klass.nil?
    self.jsonb_set_enabled = true
  end

  def self.disable_jsonb_set(klass = nil, *classes)
    remove_hash_type(*Array(klass), *classes) unless klass.nil?
    self.jsonb_set_enabled = false
  end

  def self.add_hash_type(*classes)
    self.jsonb_hash_types |= classes.flatten
  end

  def self.remove_hash_type(*classes)
    self.jsonb_set_removed |= classes.flatten
  end

  def self.merge_hash?(v)
    return false unless jsonb_set_enabled && v
    self.jsonb_hash_types.any? { |type| v.is_a?(type) }
  end

  def self.is_hash?(v)
    self.jsonb_hash_types.any? { |type| v.is_a?(type) }
  end
end


# rubocop:disable Metrics/BlockLength
ActiveSupport.on_load :active_record do
  loader.eager_load
  AssociateJsonb.class_eval do
    def self.enable_jsonb_set(klass = nil, *classes)
      if klass.nil?
        add_hash_type ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb if jsonb_hash_types.empty?
      else
        add_hash_type |= [*Array(klass), *classes].flatten
      end
      self.jsonb_set_enabled = true
    end

    self.enable_jsonb_set if jsonb_set_enabled

    def self.remove_hash_type(*classes)
      self.jsonb_hash_types -= classes.flatten
    end
    removed = jsonb_set_removed
    self.remove_hash_type removed
    self.send :remove_method, :jsonb_set_removed
    self.send :remove_method, :jsonb_set_removed=
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

  # ActiveRecord::Associations::Preloader::HasMany.prepend(
  #   AssociateJsonb::Associations::Preloader::HasMany
  # )
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
