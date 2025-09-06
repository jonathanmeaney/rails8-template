module Endpoints
  class Users < Grape::API
    # ---------- Error handling ----------
    rescue_from ActiveRecord::RecordNotFound do |e|
      error!({ error: e.message }, 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      error!({ errors: e.record.errors.full_messages }, 422)
    end

    rescue_from ActiveRecord::StaleObjectError do
      error!({ error: 'Conflict: resource was modified by someone else' }, 409)
    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      error!({ errors: e.full_messages }, 422)
    end

    helpers do
      def declared_compact
        declared(params, include_missing: false)
      end

      def user_attrs_from(p)
        (p[:user] || {})
      end

      def profile_attrs_from(p)
        (p[:profile] || {})
      end

      def load_user!(id)
        @user = User.find(id)
      end

      def apply_lock_version!(user, lock_version)
        return unless lock_version
        user.lock_version = lock_version
      end
    end

    resource :users do
      # ---------- Index ----------
      desc 'Return a list of users', success: Entities::User,
           failure: [ { code: 401, message: 'Unauthorized' } ]
      get do
        present User.all, with: Entities::User
      end

      # ---------- Show ----------
      desc 'Get a single user', success: Entities::User,
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 404, message: 'Not Found' }
           ]
      params do
        requires :id, type: Integer, desc: 'User ID'
      end
      route_param :id do
        get do
          load_user!(params[:id])
          present @user, with: Entities::User
        end
      end

      # ---------- Create ----------
      desc 'Create a new user', success: Entities::User,
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 422, message: 'Unprocessable Entity' }
           ]
      params do
        requires :user, type: Hash do
          requires :email,    type: String, desc: 'User email'
          requires :password, type: String, desc: 'User password'
        end

        optional :profile, type: Hash do
          optional :first_name, type: String, desc: 'First name'
          optional :last_name,  type: String, desc: 'Last name'
          optional :telephone,  type: String, desc: 'Telephone'
          optional :dob, type: String, desc: 'Date of birth'
        end
      end
      post do
        p = declared_compact
        user_attrs    = user_attrs_from(p)
        profile_attrs = profile_attrs_from(p)

        user = nil
        User.transaction do
          user = User.create!(user_attrs)
          user.create_profile!(profile_attrs) if profile_attrs.present?
        end

        status 201
        present user, with: Entities::User
      end

      # ---------- Update ----------
      # Use PUT here but allow partial updates (email/password optional).
      desc 'Update an existing user', success: Entities::User,
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 404, message: 'Not Found' },
             { code: 409, message: 'Conflict' },
             { code: 422, message: 'Unprocessable Entity' }
           ]
      params do
        requires :id,           type: Integer, desc: 'User ID (path)'
        requires :lock_version, type: Integer, desc: 'User version for optimistic locking'

        optional :user, type: Hash do
          optional :email,    type: String, desc: 'User email'
          optional :password, type: String, desc: 'User password'
        end

        optional :profile, type: Hash do
          optional :first_name, type: String, desc: 'First name'
          optional :last_name,  type: String, desc: 'Last name'
          optional :telephone,  type: String, desc: 'Telephone'
          optional :dob,        type: String,   desc: 'Date of birth'
        end
      end
      put ':id' do
        p = declared_compact
        load_user!(params[:id])
        apply_lock_version!(@user, p[:lock_version])

        user_attrs    = user_attrs_from(p)
        profile_attrs = profile_attrs_from(p)

        User.transaction do
          @user.update!(user_attrs) if user_attrs.present?
          if profile_attrs.present?
            @user.profile ? @user.profile.update!(profile_attrs) : @user.create_profile!(profile_attrs)
          end
        end

        present @user, with: Entities::User
      end

      # ---------- Delete ----------
      desc 'Delete a user', failure: [
        { code: 401, message: 'Unauthorized' },
        { code: 404, message: 'Not Found' },
        { code: 409, message: 'Conflict' }
      ]
      params do
        requires :id,           type: Integer, desc: 'User ID'
        requires :lock_version, type: Integer, desc: 'User version for optimistic locking'
      end
      delete ':id' do
        p = declared_compact
        load_user!(params[:id])
        apply_lock_version!(@user, p[:lock_version])

        @user.destroy!
        status 204
      end
    end
  end
end
