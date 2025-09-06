require 'fileutils'
require 'securerandom'

# Install required gems
gem 'jwt'
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger-entity'
gem 'grape-swagger-representable'
gem 'grape_logging'
gem 'bcrypt'
gem 'rack-cors', require: 'rack/cors'
gem 'foreman'

gem_group :development do
  gem 'bullet'
end

gem_group :development, :test do
  gem 'pry'
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
  gem 'rubocop'
  gem 'grape-swagger'
  gem 'rswag-ui'
  gem 'factory_bot_rails'
  gem 'faker'
end

after_bundle do
  # Install RSpec
  generate 'rspec:install'

  # Run the default Rails app generation
  generate(:model, 'User', 'email:string:uniq', 'password_digest:string', 'lock_version:integer')
  generate(:model, 'Profile', 'user:references', 'first_name:string', 'last_name:string', 'telephone:string',
           'dob:date', 'lock_version:integer')

  # Modify the generated User model file
  user_model_file = 'app/models/user.rb'
  inject_into_file user_model_file, after: "class User < ApplicationRecord\n" do
    <<-RUBY
  has_secure_password
  has_one :profile, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: -> (e) { e.strip.downcase }
    RUBY
  end

  # Modify Profile model file
  profile_model_file = 'app/models/profile.rb'
  inject_into_file profile_model_file, after: "class Profile < ApplicationRecord\n" do
    <<-RUBY
  belongs_to :user

  encrypts :first_name, deterministic: true
  encrypts :last_name, deterministic: true
  encrypts :dob, deterministic: true

  validates :first_name, :last_name, :dob, presence: true
    RUBY
  end

  # Create API structure in app/api
  # Determine template files directory relative to this template
  template_dir = File.expand_path('files', __dir__)
  api_dir = 'app/api'
  FileUtils.mkdir_p(api_dir)

  # Remove controllers dir
  FileUtils.rm_rf('app/controllers')

  # Copy API files from templates directory
  FileUtils.cp_r File.join(template_dir, 'app', 'api'), 'app/'
  FileUtils.cp_r File.join(template_dir, 'app', 'views', 'rswag'), 'app/views'
  FileUtils.cp_r File.join(template_dir, 'config', 'initializers'), 'config/'
  FileUtils.cp_r File.join(template_dir, 'spec'), 'spec/'
  FileUtils.cp_r File.join(template_dir, 'lib', 'generators'), 'lib/'
  # Copy RuboCop config to project root
  FileUtils.cp File.join(template_dir, '.rubocop.yml'), '.rubocop.yml'

  inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
    <<-RUBY
  if Rails.env.development?
    mount Rswag::Ui::Engine => '/api-docs'
  end
  mount API => '/'
    RUBY
  end

  inject_into_file 'config/application.rb', after: "class Application < Rails::Application\n" do
    <<-RUBY
  config.generators.system_tests = nil
  config.generators do |g|
    g.test_framework :rspec, fixtures: true, views: false, view_specs: false, helper_specs: false, routing_specs: false, controller_specs: false, request_specs: false
    g.fixture_replacement :factory_bot, dir: "spec/factories"
    g.stylesheets false
    g.javascripts false
    g.helper false
  end
    RUBY
  end

  # Create default user
  append_to_file 'db/seeds.rb', <<-RUBY
    user = User.create!(email: 'jon.meaney@gmail.com', password: 'password1')
    user.create_profile!(
      first_name: 'Jonathan',
      last_name: 'Meaney',
      telephone: '0123456789',
      dob: '1990-01-01'
    )
  RUBY

  # Uncomment if not using devcontainer
  # rails_command 'db:seed'

  # Generate encryption keys
  # Use Rails.application.credentials.write to set credentials programmatically
  inside Dir.pwd do
    run "bin/rails runner \"Rails.application.credentials.write({
    'secret_key_base' => SecureRandom.hex(64),
    'jwt_secret' => SecureRandom.hex(64),
    'active_record_encryption' => {
      'primary_key' => SecureRandom.hex(64),
      'deterministic_key' => SecureRandom.hex(64),
      'key_derivation_salt' => SecureRandom.hex(64)
    }
  }.transform_keys(&:to_s).to_yaml)\""
  end

  puts '✅ Rails credentials updated successfully!'
end
