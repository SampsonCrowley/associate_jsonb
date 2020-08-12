class User < ActiveRecord::Base; end
class GoodsSupplier < ActiveRecord::Base; end
class Profile < ActiveRecord::Base; end
class Account < ActiveRecord::Base; end
class Photo < ActiveRecord::Base; end
class InvoicePhoto < ActiveRecord::Base; end
class SocialProfile < ActiveRecord::Base; end
class Label < ActiveRecord::Base; end
class Group < ActiveRecord::Base; end

class User < ActiveRecord::Base
  # regular :has_one association
  has_one :profile

  # :has_one association with JSONB store
  has_one :account, foreign_store: :extra

  # regular :has_many_association
  has_many :photos

  # :has_many association with JSONB store
  has_many :social_profiles, foreign_store: :extra

  # :has_many association with JSONB store using custom key and non-standard foreign_key
  has_many :labels, foreign_store: :extra,
                    foreign_key: :owner_id,
                    foreign_store_key: :label_user,
                    inverse_of: :user

  # regular :has_and_belongs_to_many association
  has_and_belongs_to_many :groups
end

class GoodsSupplier < ActiveRecord::Base
  # :has_one association with JSONB store
  # and non-default :foreign_key
  has_one :account, foreign_store: :extra,
                    foreign_key: :supplier_id,
                    inverse_of: :supplier

  # :has_many association with JSONB store
  # and non-default :foreign_key
  has_many :invoice_photos, foreign_store: :extra,
                            foreign_key: :supplier_id,
                            inverse_of: :supplier
end

class Uuid < ActiveRecord::Base
  has_one :label, foreign_store: :extra,
                  foreign_key: :u_id,
                  foreign_store_key: :uuid,
                  inverse_of: :uuid
end

class Profile < ActiveRecord::Base
  belongs_to :user
end

class Account < ActiveRecord::Base
  belongs_to :user, store: :extra
  belongs_to :supplier, store: :extra,
                        inverse_of: :account,
                        class_name: 'GoodsSupplier'
end

class Photo < ActiveRecord::Base
  belongs_to :user
end

class InvoicePhoto < ActiveRecord::Base
  belongs_to :supplier, store: :extra, class_name: 'GoodsSupplier'
end

class SocialProfile < ActiveRecord::Base
  belongs_to :user, store: :extra
end

class Label < ActiveRecord::Base
  belongs_to :user, store: :extra, foreign_key: :owner_id, store_key: :label_user, inverse_of: :labels
  belongs_to :uuid, store: :extra, foreign_key: :u_id, store_key: :uuid, inverse_of: :label
end

class Group < ActiveRecord::Base
  has_and_belongs_to_many :users
end

class FkTest < ActiveRecord::Base
  belongs_to :user, store: :data, required: true
end

class NullTest < ActiveRecord::Base
  belongs_to :user, store: :data, required: true
end
