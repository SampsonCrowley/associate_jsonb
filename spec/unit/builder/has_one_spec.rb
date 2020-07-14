RSpec.describe ::ActiveRecord::Associations::Builder::HasOne do
  describe '.valid_options' do
    it 'adds :foreign_store as a valid option for :has_one association' do
      expect(described_class.__send__ :valid_options, {}).to include(:foreign_store)
    end

    it 'adds :foreign_store_key as a valid option for :has_many association' do
      expect(described_class.__send__ :valid_options, {}).to include(:foreign_store_key)
    end
  end
end
