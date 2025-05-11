module Entities
  class Profile < Grape::Entity
    expose :first_name
    expose :last_name
    expose :telephone
    expose :dob, format_with: :date_format
  end
end
