RSpec.shared_examples 'enum with fixed mapping' do |attr, mapping|
  it 'keeps enum integer mapping stable' do
    expect(described_class.send(attr.to_s.pluralize)).to eq(mapping.stringify_keys)
  end
end
