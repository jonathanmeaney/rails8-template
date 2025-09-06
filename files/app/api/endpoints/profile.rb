module Endpoints
  class Profile < Grape::API
    # Centralized error handling
    rescue_from ActiveRecord::RecordNotFound do |e|
      error!({ error: e.message }, 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      error!({ errors: e.record.errors.full_messages }, 422)
    end

    rescue_from ActiveRecord::StaleObjectError do |_e|
      error!({ error: 'Conflict: profile was modified by someone else' }, 409)
    end

    helpers do
      def load_profile
        @profile = current_user.profile || current_user.create_profile!
      end

      def apply_lock_version!
        @profile.lock_version = params[:lock_version] if params[:lock_version]
      end
    end

    resource :profile do
      desc 'Get current user profile' do
        success Entities::Profile
        failure [ { code: 401, message: 'Unauthorized' } ]
      end
      get do
        load_profile
        present @profile, with: Entities::Profile
      end

      desc 'Update user profile' do
        success Entities::Profile
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable Entity' }
        ]
      end
      params do
        requires :lock_version, type: Integer, desc: 'Profile version for optimistic locking'
        optional :first_name, type: String, desc: 'First name'
        optional :last_name, type: String, desc: 'Last name'
        optional :telephone, type: String, desc: 'Telephone'
        optional :dob, type: Date, desc: 'Date of birth'
      end
      put do
        load_profile
        apply_lock_version!

        if @profile.update(declared(params, include_missing: false))
          present @profile, with: Entities::Profile
        else
          error!({ errors: @profile.errors.full_messages }, 422)
        end
      end
    end
  end
end
