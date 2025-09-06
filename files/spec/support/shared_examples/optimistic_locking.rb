RSpec.shared_examples 'optimistically lockable' do |factory|
  it 'raises StaleObjectError on concurrent update' do
    a = create(factory)
    b = described_class.find(a.id)

    a.update!(name: 'first')
    expect { b.update!(name: 'second') }.to raise_error(ActiveRecord::StaleObjectError)
  end
end
