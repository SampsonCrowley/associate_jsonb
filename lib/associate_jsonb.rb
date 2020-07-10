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
loader.setup # ready!

module AssociateJsonb
end


# rubocop:disable Metrics/BlockLength
ActiveSupport.on_load :active_record do
  loader.eager_load

  ActiveRecord::Base.include AssociateJsonb::WithStoreAttribute
  ActiveRecord::Base.include AssociateJsonb::Associations

  Arel::Nodes.include AssociateJsonb::ArelNodes

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

  ActiveRecord::ConnectionAdapters::ReferenceDefinition.prepend(
    AssociateJsonb::ConnectionAdapters::ReferenceDefinition
  )
end
# rubocop:enable Metrics/BlockLength
