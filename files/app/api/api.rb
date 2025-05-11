class API < Grape::API
  prefix :api
  format :json

  helpers Authentication
  helpers APIHelpers

  rescue_from :all do |e|
    error!({ error: e.message }, 500)
  end

  before { authenticate! }

  mount Endpoints::Authentication
  mount Endpoints::Users
  mount Endpoints::Profile

  if Rails.env.development?
    add_swagger_documentation(
      api_version: '', # since we don't version leave blank
      mount_path: '/api-docs',
      info: {
        title: 'APP API',
        description: 'APP API documentation'
      },
      hide_documentation_path: true,
      hide_format: true
    )
  end
end
