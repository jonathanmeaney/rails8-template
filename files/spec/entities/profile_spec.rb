require 'rails_helper'

RSpec.describe Entities::Profile, type: :entity do
  let(:record) { build_stubbed(:profile) }
  subject(:profile) { described_class.represent(record).as_json }

  it 'exposes :id' do
    expect(profile[:id]).to eq(record.id)
  end

  it 'exposes :lock_version' do
    expect(profile[:lock_version]).to eq(record.lock_version)
  end

  it 'exposes :first_name' do
    expect(profile[:first_name]).to eq(record.first_name)
  end
  it 'exposes :last_name' do
    expect(profile[:last_name]).to eq(record.last_name)
  end

  it 'exposes :telephone' do
    expect(profile[:telephone]).to eq(record.telephone)
  end

  it 'exposes :dob' do
    expect(profile[:dob]).to eq(record.dob.strftime('%d/%m/%Y'))
  end
end
