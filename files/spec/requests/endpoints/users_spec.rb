require 'rails_helper'

RSpec.describe Endpoints::Users, type: :request do
  let(:user)          { build_stubbed(:user) }
  let(:profile)       { build_stubbed(:profile) }
  let(:profile_attrs) { assignable_attributes(:profile) }
  let(:attrs)         { assignable_attributes(:user) }

  let(:record1)    { build_stubbed(:user, attrs.merge(id: 997)) }
  let(:record2)    { build_stubbed(:user, attrs.merge(id: 998)) }
  let(:records)    { [ record1, record2 ] }
  let(:new_record) { build_stubbed(:user, attrs.merge(id: 999)) }
  let(:id)         { record1.id }

  # Payloads that the API expects (nested)
  let(:user_payload)        { paramify(attrs).stringify_keys }
  let(:profile_payload)     { paramify(profile_attrs).stringify_keys }
  let(:create_body)         { { user: user_payload, profile: profile_payload }.to_json }

  # Update payloads (only update user/profile pieces you care about)
  let(:update_user_payload)    { updated_attrs(paramify(attrs)).stringify_keys }
  let(:update_profile_payload) { updated_attrs(paramify(profile_attrs)).stringify_keys }
  let(:put_body) do
    {
      lock_version: record1.lock_version,
      user: update_user_payload,
      profile: update_profile_payload
    }.to_json
  end

  let(:json_headers) do
    auth_headers.merge('CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json')
  end

  context 'when unauthorized' do
    it 'returns 401 for GET /api/users' do
      get '/api/users', headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns 401 for GET /api/users/:id' do
      get "/api/users/#{id}", headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns 401 for POST /api/users' do
      post '/api/users', params: create_body, headers: json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns 401 for PUT /api/users/:id' do
      put "/api/users/#{id}", params: put_body, headers: json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'returns 401 for DELETE /api/users/:id' do
      delete "/api/users/#{id}",
             params: { lock_version: record1.lock_version }.to_json,
             headers: json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to be_present
    end
  end

  context 'when authorized' do
    before do
      sign_in_as(user)

      # Class-level stubs
      allow(User).to receive(:all).and_return(records)
      allow(User).to receive(:find).with(id).and_return(record1)
      allow(User).to receive(:create!).with(user_payload).and_return(new_record)

      # Instance-level stubs
      allow(new_record).to receive(:create_profile!).with(profile_payload).and_return(profile)

      # For update path:
      allow(record1).to receive(:update!) do |attrs|
        record1.assign_attributes(attrs)
        true
      end

      # Simulate an existing profile by default; change per test if needed
      allow(record1).to receive(:profile).and_return(profile)
      allow(profile).to receive(:update!).and_return(true)

      allow(record1).to receive(:destroy!).and_return(true)
    end

    describe 'GET /api/users' do
      it 'returns all records' do
        get '/api/users', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.size).to eq(records.size)
      end
    end

    describe 'GET /api/users/:id' do
      it 'returns the record' do
        get "/api/users/#{id}", headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(id)
      end

      it 'returns 404 if not found' do
        allow(User).to receive(:find).with(999).and_raise(ActiveRecord::RecordNotFound)

        get '/api/users/999', headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    describe 'POST /api/users' do
      it 'creates a record with a profile' do
        expect(User).to receive(:create!).with(user_payload).and_return(new_record)
        expect(new_record).to receive(:create_profile!).with(profile_payload)

        post '/api/users', params: create_body, headers: json_headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(new_record.id)
      end

      it 'returns 422 on validation failure' do
        invalid_user = build_stubbed(:user)
        allow(invalid_user).to receive_message_chain(:errors, :full_messages).and_return([ 'Invalid' ])

        allow(User).to receive(:create!)
          .with(user_payload)
          .and_raise(ActiveRecord::RecordInvalid.new(invalid_user))

        post '/api/users', params: create_body, headers: json_headers

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Invalid')
      end
    end

    describe 'PUT /api/users/:id' do
      it 'updates the user and profile' do
        expect(record1).to receive(:update!).with(hash_including(update_user_payload))
        expect(profile).to receive(:update!).with(hash_including(update_profile_payload))

        put "/api/users/#{id}", params: put_body, headers: json_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check a subset we know is exposed by the entity (avoid password)
        update_user_payload.except('password').each do |k, v|
          next unless json.key?(k) # entity may not expose every field
          expect(json[k]).to eq(v)
        end
      end

      it 'creates a profile if none exists and profile attrs are present' do
        allow(record1).to receive(:profile).and_return(nil)
        expect(record1).to receive(:create_profile!).with(hash_including(update_profile_payload))

        put "/api/users/#{id}", params: put_body, headers: json_headers

        expect(response).to have_http_status(:ok)
      end

      it 'returns 409 on stale lock' do
        allow(record1).to receive(:update!).and_raise(ActiveRecord::StaleObjectError.new(record1, :update))

        put "/api/users/#{id}", params: put_body, headers: json_headers

        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to match(/Conflict/i)
      end
    end

    describe 'DELETE /api/users/:id' do
      it 'deletes the record' do
        expect(record1).to receive(:destroy!).once

        delete "/api/users/#{id}",
               params: { lock_version: record1.lock_version }.to_json,
               headers: json_headers

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 409 on stale lock' do
        allow(record1).to receive(:destroy!).and_raise(ActiveRecord::StaleObjectError.new(record1, :destroy))

        delete "/api/users/#{id}",
               params: { lock_version: record1.lock_version }.to_json,
               headers: json_headers

        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to match(/Conflict/i)
      end
    end
  end
end
