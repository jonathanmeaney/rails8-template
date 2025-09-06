class API < Grape::API
  prefix :api
  format :json
  default_format :json

  helpers Authentication
  helpers APIHelpers

  use GrapeLogging::Middleware::RequestLogger,
      logger: GRAPE_REQUEST_LOGGER,
      formatter: GrapeLogging::Formatters::Rails.new,
      include: [ GrapeLogging::Loggers::FilterParameters.new,
                GrapeLogging::Loggers::ClientEnv.new ]

  rescue_from :all do |e|
    API.logger.error e
    error!({ error: e.message }, 500)
  end

  before { authenticate! }

  mount Endpoints::Authentication
  mount Endpoints::Users
  mount Endpoints::Profile

  if Rails.env.development?
    add_swagger_documentation(
      api_version: '', # since you have no versioning, leave api_version blank
      mount_path: '/api-docs',
      info: {
        title: 'API',
        description: 'API documentation'
      },
      hide_documentation_path: true,
      hide_format: true,
      security_definitions: {
        bearerAuth: {
          type: 'apiKey',
          name: 'Authorization',
          in: 'header',
          description: 'Enter: **Bearer &lt;token&gt;**'
        }
      },
      security: [ { bearerAuth: [] } ]
    )
  end
end
