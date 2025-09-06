module Authentication
  UNAUTHENTICATED_PATHS = ['/api/login', '/api/register', '/api/api-docs'].freeze

  def encode(payload)
    now = Time.now.to_i
    JWT.encode(
      {
        data: { id: payload.id, email: payload.email },
        exp: now + 3.hours.to_i,
        iat: now,
        iss: 'grape_jwt_api',
        aud: 'grape_jwt_client',
        sub: 'User',
        jti: SecureRandom.uuid,
        nbf: now + 1.second.to_i
      },
      Rails.application.credentials.jwt_secret,
      'HS256',
      { typ: 'JWT', alg: 'HS256' }
    )
  end

  def decode(token)
    JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: 'HS256')
  end

  def current_user
    @current_user ||= begin
      decoded_token = decode(get_token)
      decoded_token.first['data'].with_indifferent_access
    rescue JWT::DecodeError => e
      error!({ error: "Invalid token: #{e.message}" }, 401)
    rescue JWT::ExpiredSignature
      error!({ error: 'Token has expired' }, 401)
    end
  end

  private

  def get_token
    token = headers['Authorization']&.split(' ')&.last
    error!({ error: 'Token missing' }, 401) unless token
    token
  end

  def authenticate!
    return if UNAUTHENTICATED_PATHS.include?(request.path)

    current_user || error!({ error: 'Unauthorized' }, 401)
  end
end
