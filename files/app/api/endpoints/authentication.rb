module Endpoints
  class Authentication < Grape::API
    desc 'Authenticate user'
    params do
      requires :email, type: String, desc: 'User email'
      requires :password, type: String, desc: 'User password'
    end
    post :login do
      user = User.find_by(email: params[:email])
      if user && user.authenticate(params[:password])
        token = encode(user)
        header 'Authorization', "Bearer #{token}"

        present user, with: Entities::User
      else
        error!('Unauthorized', 401)
      end
    end
  end
end
