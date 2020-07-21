RSpec.describe 'thread_safe json' do
  let(:model) { Label.new }
  let(:default_value) do
    {
      key_1: 1,
      key_2: 2,
      key_3: {
        key_4: 7,
        key_5: 8,
        key_6: 9
      }
    }.deep_stringify_keys
  end

  describe '#update' do
    before do
      model.update(extra: default_value)
      expect(model.extra).to eq(default_value)
    end

    it "only updates changed hash keys" do
      value = default_value.dup
      model.update(extra: { key_1: nil })
      value["key_1"] = nil
      expect(model.extra).to eq(value)
      value.delete("key_1")
      expect(model.reload.extra).to eq(value)

      model.update(extra: { key_2: nil })
      value["key_2"] = nil
      expect(model.extra).to eq(value)
      value.delete("key_2")
      expect(model.reload.extra).to eq(value)

      model.update(extra: { key_3: { key_4: nil, key_5: "test" } })
      value["key_3"].merge!("key_4" => nil, "key_5" => "test")
      expect(model.extra).to eq(value)
      expect(model.extra["key_3"]["key_4"]).to be_nil
      expect(model.extra["key_3"]["key_5"]).to eq("test")
      expect(model.extra["key_3"]["key_6"]).to eq(9)
      value["key_3"].delete("key_4")
      expect(model.reload.extra).to eq(value)

      model.update(extra: { key_3: nil })
      value["key_3"] = nil
      expect(model.extra).to eq(value)
      value.delete("key_3")
      expect(model.reload.extra).to eq(value)

      model.class.where(id: model.id).update(extra: { a: { b: { c: {} }} })
      expect(model.extra).to eq(value)
      value["a"] = { "b" => { "c" => {}}}
      expect(model.reload.extra).to eq(value)

    end
  end
end
