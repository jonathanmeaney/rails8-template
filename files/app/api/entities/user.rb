module Entities
  class User < Grape::Entity
    expose :id
    expose :email
    expose :created_at, format_with: :date_time_format
    expose :lock_version
    expose :profile, using: Entities::Profile, if: ->(user, _options) { user.profile.present? }
  end
end
