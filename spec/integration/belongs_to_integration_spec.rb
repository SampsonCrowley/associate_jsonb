# rubocop:disable Metrics/BlockLength
RSpec.shared_examples ":belongs_to association" do |store_type: :regular, reflection_type: :has_one|
  let(:parent_class) { parent_model.class }
  let(:child_class) { child_model.class }
  let(:parent_name) { parent_model.model_name.element }
  let(:child_name) { child_model.model_name.element }

  describe "#association" do
    before do
      if store_type == :jsonb
        child_model.update store => { store_key => parent_model.id }
      else
        child_model.update foreign_key => parent_model.id
      end
    end

    it "properly loads association from parent model" do
      expect(child_model.reload.send(parent_name)).to eq(parent_model)
    end
  end

  describe "#association=" do
    before do
      child_model.update parent_name => parent_model
    end

    it "sets and persists foreign key in jsonb store on child model", if: store_type.eql?(:jsonb) do
      expect(
        child_model.reload.send(store)
      ).to eq(store_key => parent_model.id)
    end

    it "sets and persists regular foreign key on child model", if: store_type.eql?(:regular) do
      expect(child_model.reload.send(foreign_key)).to eq(parent_model.id)
    end
  end

  describe "association_id", if: store_type.eql?(:jsonb) do
    before do
      child_model.update store => { store_key => parent_model.id }
    end

    it "reads foreign id from specified :store column by foreign key" do
      expect(child_model.send(foreign_key)).to eq parent_model.id
    end
  end

  describe "#association_id=", if: store_type.eql?(:jsonb) do
    before do
      child_model.send "#{foreign_key}=", parent_model.id
    end

    it "sets foreign id in specified :store column as hash item" do
      expect(child_model.send(store)[store_key]).to eq(parent_model.id)
    end
  end

  describe "#build_association" do
    let!(:built_association) do
      child_model.send("build_#{parent_name}")
    end

    it "sets foreign key on child model in jsonb store on parent save", if: store_type.eql?(:jsonb) && reflection_type.eql?(:has_one) do
      built_association.save

      expect(child_model.send(store)).to eq(store_key => built_association.id)
    end

    it "sets foreign key on child model on parent save", if: reflection_type.eql?(:has_one) do
      built_association.save

      expect(child_model.send(foreign_key)).to eq(built_association.reload.id)
    end

    it "sets foreign key on child model save in jsonb store after parent save", if: store_type.eql?(:jsonb) && reflection_type.eql?(:has_many) do
      built_association.save
      built_association.reload

      expect(child_model.send(parent_name)).to eq(built_association)
      expect(child_model.send(store)).to eq({})

      child_model.save

      expect(child_model.send(store)).to eq(store_key => built_association.id)
    end

    it "sets foreign key on child model save after parent save", if: reflection_type.eql?(:has_many) do
      built_association.save
      built_association.reload

      expect(child_model.send(foreign_key)).to be_nil
      expect(child_model.send(parent_name)).to eq(built_association)

      child_model.save

      expect(child_model.send(foreign_key)).to eq(built_association.reload.id)
    end
  end

  describe "#create_association" do
    let!(:created_association) do
      child_model.send "create_#{parent_name}"
    end

    it "sets and persists foreign key on child model in jsonb store", if: store_type.eql?(:jsonb) && reflection_type.eql?(:has_one) do
      expect(child_model.reload.send(store)).to eq(store_key => created_association.id)
    end

    it "sets and persists foreign key on child model", if: reflection_type.eql?(:has_one) do
      expect(child_model.reload.send(foreign_key)).to eq(created_association.id)
    end

    it "sets foreign key on child model in jsonb store", if: store_type.eql?(:jsonb) && reflection_type.eql?(:has_many) do
      expect(child_model.send(store)).to eq(store_key => created_association.id)
    end

    it "sets and persists foreign key on child model", if: reflection_type.eql?(:has_many) do
      expect(child_model.send(foreign_key)).to eq(created_association.id)
    end
  end

  describe "#reload_association" do
    before do
      child_model.send :"#{parent_name}=", parent_model
    end

    it "reloads association" do
      expect(child_model.send("reload_#{parent_name}")).to eq(parent_model)
    end
  end

  describe "#preload / #includes" do
    before do
      parent_class.destroy_all
      create_list(child_name, 3, "with_#{parent_name}".to_sym)
    end

    it "makes 2 queries" do
      expect(count_queries do
        child_class.all.preload(parent_name).map do |record|
          record.send(parent_name).id
        end
      end).to eq(2)
    end
  end

  describe "#eager_load / #joins" do
    before do
      parent_class.destroy_all
      create_list(child_name, 3, "with_#{parent_name}".to_sym)
    end

    it "makes 1 query" do
      expect(count_queries do
        child_class.all.eager_load(parent_name).map do |record|
          record.send(parent_name).id
        end
      end).to eq(1)
    end
  end
end

RSpec.describe ":belongs_to" do
  context "regular association" do
    context "has_one" do
      include_examples ":belongs_to association" do
        let(:parent_model) { User.create }
        let(:child_model) { Profile.new }
        let(:foreign_key) { :user_id }
        let(:store_key) { "user_id" }
      end
    end

    context "has_many" do
      include_examples ":belongs_to association", reflection_type: :has_many do
        let(:parent_model) { User.create }
        let(:child_model) { Photo.new }
        let(:foreign_key) { :user_id }
        let(:store_key) { "user_id" }
      end
    end
  end

  context "association with :store option set on child model" do
    context "with default options" do
      include_examples ":belongs_to association", store_type: :jsonb do
        let(:parent_model) { User.create }
        let(:child_model) { Account.new }
        let(:store) { :extra }
        let(:foreign_key) { :user_id }
        let(:store_key) { "user_id" }
      end
    end

    context "with non-default :options" do
      context "(foreign_key)" do
        include_examples ":belongs_to association", store_type: :jsonb do
          let(:parent_model) { GoodsSupplier.create }
          let(:parent_name) { :supplier }
          let(:child_model) { Account.new }
          let(:store) { :extra }
          let(:foreign_key) { :supplier_id }
          let(:store_key) { "supplier_id" }
        end
      end

      context "(foreign_key, store_key)" do
        include_examples ":belongs_to association", store_type: :jsonb, reflection_type: :has_many do
          let(:parent_model) { User.create }
          let(:parent_name) { :user }
          let(:child_model) { Label.new }
          let(:store) { :extra }
          let(:foreign_key) { :owner_id }
          let(:store_key) { "label_user" }
        end
      end
    end

    context "when 2 associations on one model have the same foreign_key" do
      it "raises an error" do
        expect do
          class Foo < User
            belongs_to :bar, store: :extra, foreign_key: :bar_id, class_name: "User"
            belongs_to :baz, store: :extra, foreign_key: :bar_id, class_name: "User"
          end
        end.to raise_error(
          AssociateJsonb::Associations::ConflictingAssociation,
          "Association with foreign key :bar_id already exists on Foo"
        )
      end
    end
  end
end
