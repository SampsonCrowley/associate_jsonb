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
    }.as_json
  end

  describe '#update' do
    context "AssociateJsonb.jsonb_set_enabled" do
      before do
        AssociateJsonb.enable_jsonb_set
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

        model.update(extra: ActiveSupport::JSON.encode({ key_2: nil }))
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

        model.update(extra: { a: { b: { c: {} }} })
        value["a"] = { "b" => { "c" => {}}}
        expect(model.extra).to eq(value)
        value["a"] = { "b" => { "c" => {}}}
        expect(model.reload.extra).to eq(value)

        model.update(extra: { d: 1, e: { f: nil } })
        value.merge!({ "d" => 1, "e" => { "f" => nil } })
        expect(model.extra).to eq(value)
        value["e"] = {}
        expect(model.reload.extra).to eq(value)
        model.update( extra: { a: { b: { c: nil, z: 1 } }, e: nil } )
        value["e"] = nil
        value["a"]["b"]["c"] = nil
        value["a"]["b"]["z"] = 1
        expect(model.extra).to eq(value)
        value.delete("e")
        value["a"]["b"].delete("c")
        expect(model.reload.extra).to eq(value)

      end
    end

    context "!AssociateJsonb.jsonb_set_enabled" do
      context "!AssociateJsonb.jsonb_delete_nil" do
        before do
          AssociateJsonb.disable_jsonb_set
          AssociateJsonb.jsonb_delete_nil = false
          model.update(extra: default_value)
          expect(model.extra).to eq(default_value)
        end

        it "replaces the document" do
          %i[
            key_1
            key_2
            key_3
          ].each do |k|
            value = { k => nil }
            model.update(extra: value)
            expect(model.extra).to eq(value.as_json)
            expect(model.reload.extra).to eq(value.as_json)
          end
          [
            { key_3: { key_4: nil, key_5: "test", "key_6" => { a: 1 } } },
            { a: { b: { c: {} }} }
          ].each do |value|
            model.update(extra: value)
            expect(model.extra).to eq(value.as_json)
            expect(model.reload.extra).to eq(value.as_json)
          end
        end
      end


      context "AssociateJsonb.jsonb_delete_nil" do
        before do
          AssociateJsonb.jsonb_delete_nil = true
          model.update(extra: default_value)
          expect(model.extra).to eq(default_value)
        end

        it "replaces the document with no null keys" do
          %i[
            key_1
            key_2
            key_3
          ].each do |k|
            value = { k => nil }
            model.update(extra: value)
            expect(model.extra).to eq(value.as_json)
            expect(model.reload.extra).to eq({})
          end
          [
            { key_3: { key_4: nil, key_5: "test", "key_6" => { a: 1 } } },
            { a: { b: { c: {}, e: "" }} }
          ].each do |value|
            model.update(extra: value)
            expect(model.extra).to eq(value.as_json)
            value[:key_3]&.delete :key_4
            expect(model.reload.extra).to eq(value.as_json)
          end
        end
      end

    end
  end
end
