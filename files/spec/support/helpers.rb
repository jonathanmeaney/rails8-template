# frozen_string_literal: true

require 'bigdecimal'

def paramify(values)
  values.transform_values do |v|
    case v
    when Date
      v.strftime('%d/%m/%Y')
    when DateTime, Time
      v.strftime('%d/%m/%Y %H:%M:%S')
    else
      v.to_s
    end
  end
end

def assignable_attributes(factory_model)
  attributes_for(factory_model)
    .except(
      :id,
      :lock_version,
      :created_at,
      :updated_at,
      :password_digest
    )
end

def updated_attrs(attrs)
  # Keys to never mutate (works with symbol or string keys)
  excluded_keys = %i[id created_at updated_at lock_version]
  # Also skip foreign keys, etc.
  excluded_key_patterns = [ /_id\z/ ]

  transform = lambda do |value|
    case value
    when String                     then "#{value}_updated"
    when Integer                    then value + 1
    when Float                      then value + 1.0
    when BigDecimal                 then value + BigDecimal('1')
    when TrueClass, FalseClass      then !value
    when Date, DateTime             then value + 1.day
    when Time, ActiveSupport::TimeWithZone
                                     then value + 1.hour
    when Symbol                     then :"#{value}_updated"
    when Array                      then value.map { |e| transform.call(e) }
    when Hash
      value.each_with_object(value.class.new) do |(k, v), h|
        key_str = k.to_s
        if excluded_keys.include?(k.to_sym) || excluded_key_patterns.any? { |re| re.match?(key_str) }
          h[k] = v
        else
          h[k] = transform.call(v)
        end
      end
    else
      value
    end
  end

  transform.call(attrs.deep_dup)
end

# Call this in your request specs before making the call.
# It stubs `authenticate!` and `current_user` on your API class.
#
# Replace `Api::V1::Base` with whatever class your endpoints are mounted under.
def sign_in_as(user = build_stubbed(:user))
  allow(JWT).to receive(:decode).and_return([
    { 'data' => { 'id' => user.id } }
  ])
  allow(User).to receive(:find).with(user.id).and_return(user)

  # Optional: set a dummy Authorization header so your params block that
  # requires a header still sees one.
  @__auth_headers__ = { 'Authorization' => 'Bearer test-token' }

  user
end

# Convenience for merging headers in requests
def auth_headers(extra = {})
  base = {
    'ACCEPT' => 'application/json'
    # Causes specs to fail as apparently we aren't responding with json
    # 'CONTENT_TYPE' => 'application/json'
  }
  base.merge(@__auth_headers__ || {}).merge(extra)
end
