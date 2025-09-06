# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:model) { build(:user) } # uses FactoryBot

  # ===== Factories =====
  it 'has a valid factory' do
    expect(build(:user)).to be_valid
    # expect { create(:user) }.to change(described_class, :count).by(1)
  end

  # ===== Optimistic locking (if you use lock_version) =====
  it_behaves_like 'optimistically lockable', :user

  # ===== Database =====
  # describe 'database' do
  #   it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
  #   it { is_expected.to have_db_column(:status).of_type(:integer).with_options(null: false, default: 0) }
  #   it { is_expected.to have_db_index(:name).unique(true) }
  #   it { is_expected.to have_db_index([ :account_id, :external_id ]).unique(true) }
  #   it { is_expected.to belong_to(:account).required(true) } # implies FK check in schema
  # end

  # ===== Associations =====
  describe 'associations' do
    it { is_expected.to have_one(:profile).dependent(:destroy) }
  end

  # ===== Validations =====
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:account_id).case_insensitive }
    it { is_expected.to allow_value('foo@example.com').for(:email) }
    it { is_expected.not_to allow_value('nope').for(:email) }
  end

  # ===== Enums =====
  # describe 'enums' do
  #   it do
  #     is_expected.to define_enum_for(:status)
  #       .with_values(draft: 0, active: 1, archived: 2)
  #       .backed_by_column_of_type(:integer)
  #   end

  #   it 'has working predicates' do
  #     m = build(:user, status: :active)
  #     expect(m).to be_active
  #     m.archived!
  #     expect(m).to be_archived
  #   end
  # end

  # ===== Delegations =====
  # describe 'delegations' do
  #   it { is_expected.to delegate_method(:owner_name).to(:account).with_prefix(:account).allow_nil }
  # end

  # ===== Scopes =====
  # describe 'scopes' do
  #   let!(:draft)   { create(:user, status: :draft) }
  #   let!(:active)  { create(:user, status: :active) }
  #   let!(:archived) { create(:user, status: :archived) }

  #   it '.active returns only active records' do
  #     expect(described_class.active).to contain_exactly(active)
  #   end

  #   it 'scopes compose' do
  #     expect(described_class.active.order(:id)).to eq([ active ])
  #   end
  # end

  # ===== Callbacks =====
  # describe 'callbacks' do
  #   it 'normalizes name before validation' do
  #     m = build(:user, name: "  Foo  ")
  #     m.validate
  #     expect(m.name).to eq('Foo')
  #   end
  # end

  # ===== Serialization / store accessors =====
  # describe 'serialization' do
  #   it 'round-trips settings JSON' do
  #     m = build(:user, settings: { 'dark_mode' => true, 'limit' => 5 })
  #     m.save!
  #     m.reload
  #     expect(m.settings).to include('dark_mode' => true, 'limit' => 5)
  #   end
  # end

  # ===== Business logic =====
end
