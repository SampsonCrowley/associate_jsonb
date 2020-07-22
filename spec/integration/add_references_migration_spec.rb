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

  let(:foo_index_on_uuid) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_uuid"
    end
  end

  let(:foo_index_on_uuid_text) do
    schema_cache.connection.indexes(SocialProfile.table_name).find do |index|
      index.name == "index_social_profiles_on_foo_uuid_text"
    end
  end

  let(:foo_fk_constraint_on_uuid) do
    schema_cache.connection.constraints(SocialProfile.table_name).find do |constraint|
      constraint[:name] == "social_profiles_uuid_foreign_key"
    end
  end

  let(:non_null_constraint) do
    schema_cache.connection.constraints(FkTest.table_name).find do |constraint|
      constraint[:name] == "fk_tests_user_id_foreign_key"
    end
  end

  describe '#change' do
    before(:all) do
      class AddUsersReferenceToSocialProfiles < ActiveRecord::Migration[5.1]
        def change
          add_reference :social_profiles, :user, store: :foo
          add_reference :social_profiles, :supplier, store: :foo, index: false
          add_reference :social_profiles, :uuid, store: :foo, store_key: :uuid, type: :uuid, foreign_key: true
        end
      end

      AddUsersReferenceToSocialProfiles.new.change
      ActiveRecord::Base.connection.schema_cache.clear!
    end

    it "creates :foo column with :jsonb type" do
      expect(foo_column).to be_present
      expect(foo_column.type).to eq(:jsonb)
    end

    it "creates casted a bigint index on foo->>'user_id'" do
      expect(foo_index_on_user_id).to be_present
      expect(foo_index_on_user_id.columns).to eq("(((foo ->> 'user_id'::text))::bigint)")
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

    it "creates a uuid casted index on foo->>'uuid'" do
      expect(foo_index_on_uuid).to be_present
      expect(foo_index_on_uuid.columns).to eq("(((foo ->> 'uuid'::text))::uuid)")
    end

    it "creates text index on foo->>'uuid'" do
      expect(foo_index_on_uuid_text).to be_present
      expect(foo_index_on_uuid_text.columns).to eq("((foo ->> 'uuid'::text))")
    end

    it "creates a nullable check constraint fk on foo->>'uuid'" do
      expect(foo_fk_constraint_on_uuid).to be_present
      expect(foo_fk_constraint_on_uuid[:type]).to eq("CHECK")
      expect(foo_fk_constraint_on_uuid[:definition]).to eq("CHECK (jsonb_foreign_key('uuids'::text, 'id'::text, foo, 'uuid'::text, 'uuid'::text, true)) NOT VALID")
      Uuid.where(id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa').delete_all
      expect {
        SocialProfile.
          new(foo: {uuid: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'}).
          save(validate: false)
      }.to raise_error(
        ActiveRecord::StatementInvalid,
        /^PG::CheckViolation:\s+ERROR:.+row.+violates\s+check\s+constraint\s+"social_profiles_uuid_foreign_key"/
      )

      expect(SocialProfile.new(foo: {uuid: nil}).save).to be true
    end

    it "creates a non-null check constraint fk on data->>'user_id'" do
      expect(non_null_constraint).to be_present
      expect(non_null_constraint[:type]).to eq("CHECK")
      expect(non_null_constraint[:definition]).to eq("CHECK (jsonb_foreign_key('users'::text, 'id'::text, data, 'user_id'::text, 'bigint'::text, false)) NOT VALID")

      error_reg = /^PG::CheckViolation:\s+ERROR:.+row.+violates\s+check\s+constraint\s+"fk_tests_user_id_foreign_key"/

      [
        { user_id: 0 },
        { user_id: nil },
        {}
      ].each do |v|
        expect {
          FkTest.
            new(data: v).
            save(validate: false)
        }.to raise_error(
          ActiveRecord::StatementInvalid,
          error_reg
        )
      end

      expect(FkTest.new(data: {user_id: User.create.id}).save(validate: false)).to be true
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
