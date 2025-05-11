module Endpoints
  class Users < Grape::API
    resource :users do
      desc 'Return a list of users'
      get do
        users = User.all
        present users, with: Entities::User
      end

      desc 'Create a new user',
           success: { code: 201, message: 'User created successfully' },
           failure: [{ code: 400, message: 'Invalid parameters' }]
      params do
        requires :email, type: String, desc: 'User email'
        requires :password, type: String, desc: 'User password'
        optional :first_name, type: String, desc: 'First name'
        optional :last_name, type: String, desc: 'Last name'
        optional :telephone, type: String, desc: 'Telephone'
        optional :dob, type: Date, desc: 'Date of birth'
      end
      post do
        user = User.create!(email: params[:email], password: params[:password])
        user.create_profile!(
          first_name: params[:first_name] || '',
          last_name: params[:last_name] || '',
          telephone: params[:telephone] || '',
          dob: params[:dob]
        )

        present user, with: Entities::User
      end
    end
  end
end
