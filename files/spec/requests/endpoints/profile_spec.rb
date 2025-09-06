require 'rails_helper'

RSpec.describe Endpoints::Profile, type: :request do
  let(:user) { build_stubbed(:user) }
  let(:profile) { build_stubbed(:profile) }
  let(:attrs) { assignable_attributes(:profile) }

  let(:id)           { profile.id }
  let(:valid_attrs)  { attrs }
  let(:update_attrs) { updated_attrs(valid_attrs) }

  context 'when unauthorized' do
    it 'returns 401 for GET /api/profile' do
      get '/api/profile', headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns 401 for PUT /api/profile' do
      put '/api/profile/', params: update_attrs.merge(lock_version: profile.lock_version).to_json, headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end
  end

  context 'when authorized' do
    before do
      sign_in_as(user)
      allow(user).to receive(:profile).and_return profile
      allow(user).to receive(:create_profile!).and_return profile

      # Stub instance methods
      allow(profile).to receive(:update).and_return true
      allow(profile).to receive(:update) do |attrs|
        profile.assign_attributes(attrs)
        true
      end
    end

    describe 'GET /api/profile' do
      it 'returns the record' do
        get '/api/profile', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['first_name']).to eq(profile.first_name)
        expect(json['last_name']).to eq(profile.last_name)
        expect(json['telephone']).to eq(profile.telephone)
        expect(json['dob']).to eq(profile.dob.strftime('%d/%m/%Y'))
      end
    end

    describe 'PUT /api/profile' do
      let(:locked_params) { update_attrs.merge(lock_version: profile.lock_version) }

      it 'updates the record' do
        expect(profile).to receive(:update).with(hash_including(update_attrs))

        put '/api/profile', params: locked_params, headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body).with_indifferent_access
        update_attrs.each do |k, v|
          value = case v
          when Date
            v.strftime('%d/%m/%Y')
          when DateTime
            v.strftime('%d/%m/%Y %H:%M:%S')
          else
            v.to_s
          end
          expect(json[k.to_s]).to eq(value)
        end
      end

      it 'returns 409 on stale lock' do
        allow(profile).to receive(:update).and_raise(ActiveRecord::StaleObjectError.new(profile, :update))

        put '/api/profile', params: locked_params, headers: auth_headers

        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to match(/Conflict/)
      end
    end
  end
end
