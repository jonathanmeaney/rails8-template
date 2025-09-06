require 'rails_helper'

RSpec.describe Entities::User, type: :entity do
  let(:record) { build_stubbed(:user) }
  subject(:user) { described_class.represent(record).as_json }

  it 'exposes :id' do
    expect(user[:id]).to eq(record.id)
  end

  it 'exposes :lock_version' do
    expect(user[:lock_version]).to eq(record.lock_version)
  end

  it 'exposes :email' do
    expect(user[:email]).to eq(record.email)
  end
  it 'exposes :created_at' do
    expect(user[:created_at]).to eq(record.created_at.strftime('%d/%m/%Y %H:%M:%S'))
  end

  it 'exposes :profile' do
    expect(user[:profile]).to eq(record.profile)
  end
end
