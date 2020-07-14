RSpec.describe ::ActiveRecord::Associations::Builder::BelongsTo do
  describe '.valid_options' do
    it 'adds :store as a valid option for :belongs_to association' do
      expect(described_class.__send__ :valid_options, {}).to include(:store)
    end

    it 'adds :store_key as a valid option for :has_many association' do
      expect(described_class.__send__ :valid_options, {}).to include(:store_key)
    end
  end
end
