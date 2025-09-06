# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe Profile, type: :model do
  subject(:model) { build(:profile) } # uses FactoryBot

  # ===== Factories =====
  it 'has a valid factory' do
    expect(build(:profile)).to be_valid
  end

  # ===== Optimistic locking (if you use lock_version) =====
  it_behaves_like 'optimistically lockable', :profile

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
    it { is_expected.to belongs_to(:user) }
  end

  # ===== Validations =====
  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:dob) }
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
