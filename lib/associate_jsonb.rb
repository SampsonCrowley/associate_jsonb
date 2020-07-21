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
loader.setup # ready!

module AssociateJsonb
  mattr_accessor :safe_hash_classes, default: [
    ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
  ]
end


# rubocop:disable Metrics/BlockLength
ActiveSupport.on_load :active_record do
  loader.eager_load

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

  ActiveRecord::Reflection::AbstractReflection.prepend AssociateJsonb::Reflection
  ActiveRecord::PredicateBuilder.prepend AssociateJsonb::PredicateBuilder
  ActiveRecord::Relation::WhereClause.prepend AssociateJsonb::Relation::WhereClause

  ActiveRecord::ConnectionAdapters::ReferenceDefinition.prepend(
    AssociateJsonb::ConnectionAdapters::ReferenceDefinition
  )
end
# rubocop:enable Metrics/BlockLength
