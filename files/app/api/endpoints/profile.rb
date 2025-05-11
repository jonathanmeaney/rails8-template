module Endpoints
  class Profile < Grape::API
    resource :profile do
      desc 'Update user profile'
      params do
        optional :first_name, type: String, desc: 'First name'
        optional :last_name, type: String, desc: 'Last name'
        optional :telephone, type: String, desc: 'Telephone'
        optional :dob, type: Date, desc: 'Date of birth'
      end
      put do
        profile = current_user.profile || current_user.create_profile!

        profile.update!(
          first_name: params[:first_name] || profile.first_name,
          last_name: params[:last_name] || profile.last_name,
          telephone: params[:telephone] || profile.telephone,
          dob: params[:dob] || profile.dob
        )

        present profile, with: Entities::Profile
      end
    end
  end
end
