FactoryBot.define do
  factory :user do
    id { 1 }
    lock_version { 0 }
    email { 'jon.meaney@gmail.com' }
    password { 'password1' }
    password_digest { 'password_digest' }
    created_at { Date.civil(2025, 1, 1) }
    updated_at { Date.civil(2025, 1, 1) }
  end
end
