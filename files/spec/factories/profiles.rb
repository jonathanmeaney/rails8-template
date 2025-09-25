FactoryBot.define do
  factory :profile do
    user { :user }
    id { 1 }
    lock_version { 0 }
    first_name { 'jonathan' }
    last_name { 'meaney' }
    telephone { '003531234567' }
    dob { Date.civil(1990, 1, 1) }
    created_at { Date.civil(2025, 1, 1) }
    updated_at { Date.civil(2025, 1, 1) }
  end
end
