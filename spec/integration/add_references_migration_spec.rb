# rubocop:disable Metrics/BlockLength
RSpec.describe ':add_references migration command' do
  let(:schema_cache) do
    ActiveRecord::Base.connection.schema_cache
  end

  let(:foo_column) do
    schema_cache.columns_hash(SocialProfile.table_name)['foo']
  end

  let(:foo_index_on_user_id) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_user_id"
    end
  end

  let(:foo_index_on_user_id_text) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_user_id_text"
    end
  end

  let(:foo_index_on_supplier_id) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_supplier_id"
    end
  end

  let(:foo_index_on_supplier_id_text) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_supplier_id_text"
    end
  end

  describe '#change' do
    before(:all) do
      class AddUsersReferenceToSocialProfiles < ActiveRecord::Migration[5.1]
        def change
          add_reference :social_profiles, :user, store: :foo
          add_reference :social_profiles, :supplier, store: :foo, index: false
        end
      end

      AddUsersReferenceToSocialProfiles.new.change
      ActiveRecord::Base.connection.schema_cache.clear!
    end

    it "creates :foo column with :jsonb type" do
      expect(foo_column).to be_present
      expect(foo_column.type).to eq(:jsonb)
    end

    it "creates casted index on foo->'user_id'" do
      expect(foo_index_on_user_id).to be_present
      expect(foo_index_on_user_id.columns).to eq("(((foo -> 'user_id'::text))::bigint)")
    end

    it "creates text index on foo->>'user_id'" do
      expect(foo_index_on_user_id_text).to be_present
      expect(foo_index_on_user_id_text.columns).to eq("((foo ->> 'user_id'::text))")
    end

    it "does not create an index on foo->>'supplier_id'" do
      expect(foo_index_on_supplier_id).to be_nil
    end

    it "does not create a text index on foo->'supplier_id'" do
      expect(foo_index_on_supplier_id_text).to be_nil
    end
  end

  describe 'index usage' do
    let(:parent) { create :user }
    let!(:children) { create_list :social_profile, 1000, user: parent }
    let(:index_name) { 'index_social_profiles_on_extra_user_id' }

    it "does index scan when getting associated models" do
      expect(
        parent.social_profiles.explain
      ).to include("Bitmap Index Scan on #{index_name}")
    end

    it "does index or hash scan on #eager_load" do
      expect(User.all.eager_load(:social_profiles).explain).
        to match(/Hash\s+Cond:\s+\(+social_profiles.extra[^)]+\)+::bigint\s+\=\s+users.id/).
        or( include("Index Scan using #{index_name}") )
    end
  end
end
# rubocop:enable Metrics/BlockLength
