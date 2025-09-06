module Entities
  class Profile < Grape::Entity
    expose :id
    expose :first_name
    expose :last_name
    expose :telephone
    expose :dob, format_with: :date_format
    expose :lock_version
  end
end
