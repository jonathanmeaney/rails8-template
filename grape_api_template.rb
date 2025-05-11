require 'fileutils'
require 'securerandom'

# Install required gems
gem 'jwt'
gem 'grape'
gem 'grape-entity'
gem 'bcrypt'
gem 'rack-cors', require: 'rack/cors'
gem 'foreman'

gem_group :development do
  gem 'bullet'
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'grape-swagger'
  gem 'rswag-ui'
end

after_bundle do
  # Install RSpec
  generate 'rspec:install'

  # Run the default Rails app generation
  generate(:model, 'User', 'email:string:uniq', 'password_digest:string')
  generate(:model, 'Profile', 'user:references', 'first_name:string', 'last_name:string', 'telephone:string',
           'dob:date')

  # Migrate the database
  rails_command 'db:migrate'

  # Modify the generated User model file
  user_model_file = 'app/models/user.rb'
  inject_into_file user_model_file, after: "class User < ApplicationRecord\n" do
    <<-RUBY
  has_secure_password
  has_one :profile

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
  api_dir = 'app/api'
  FileUtils.mkdir_p(api_dir)

  # Remove controllers dir
  FileUtils.rm_rf('app/controllers')

  # Copy API files from templates directory
  template_dir = '/Users/jonathanmeaney/Development/rails/templates/files'

  FileUtils.cp_r "#{template_dir}/app/api", 'app/'
  FileUtils.cp_r "#{template_dir}/app/views/rswag", 'app/views'
  FileUtils.cp_r "#{template_dir}/config/initializers", 'config/'

  inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
    <<-RUBY
      if Rails.env.development?
        mount Rswag::Ui::Engine => '/api-docs'
      end
      mount API => '/'
    RUBY
  end

  # Create default user
  append_to_file 'db/seeds.rb', <<-RUBY
    user = User.create!(email: 'jon.meaney@gmail.com', password: 'password1')
    user.create_profile!(
      first_name: 'Jonathan',
      last_name: 'Meaney',
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
