module Endpoints
  class Authentication < Grape::API
    desc 'Authenticate user'
    params do
      requires :email, type: String, desc: 'User email', documentation: { example: 'jon.meaney@gmail.com' }
      requires :password, type: String, desc: 'User password', documentation: { example: 'password1' }
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

    desc 'Register user'
    params do
      requires :email, type: String, desc: 'User email'
      requires :password, type: String, desc: 'User password'
    end
    post :register do
      user = User.new(email: params[:email], password: params[:password])

      if user.save
        token = encode(user)
        header 'Authorization', "Bearer #{token}"

        present user, with: Entities::User
      else
        error!('Already registered', 409)
      end
    end
  end
end
