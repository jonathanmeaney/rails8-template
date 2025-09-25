require 'rails/generators'
require 'rails/generators/active_record/model/model_generator'

class ModelWithEntityGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :attributes, type: :array, default: [], banner: 'field:type field:type'

  # 1) Generate the AR model
  def create_active_record_model
    args = [ name ] + attributes.map(&:to_s)
    args << 'lock_version:integer' unless args.any? { |a| a.start_with?('lock_version:') }
    Rails::Generators.invoke(
      'active_record:model',
      args,
      behavior: behavior,
      destination_root: destination_root
    )
  end

  # 2) Generate the Grape::Entity under app/entities
  def create_grape_entity
    template(
      'entity.rb.tt',
      File.join('app', 'api', 'entities', "#{file_name}.rb")
    )
  end

  # 3) Generate the Grape::API endpoints under app/endpoints
  def create_grape_endpoints
    template(
      'endpoints.rb.tt',
      File.join('app', 'api', 'endpoints', "#{plural_file_name}.rb")
    )
  end

  # 4) RSpec model spec
  def create_model_spec
    template(
      'spec/models/model_spec.rb.tt',
      File.join('spec', 'models', "#{file_name}_spec.rb")
    )
  end

  # 5) RSpec entity spec under spec/entities
  def create_entity_spec
    template(
      'spec/entities/entity_spec.rb.tt',
      File.join('spec', 'entities', "#{file_name}_spec.rb")
    )
  end

  # 6) RSpec endpoint spec under spec/endpoints
  def create_endpoint_spec
    template(
      'spec/requests/endpoints/endpoints_spec.rb.tt',
      File.join('spec', 'requests', 'endpoints', "#{plural_file_name}_spec.rb")
    )
  end

  private

  def entity_class_name
    class_name
  end

  def plural_file_name
    file_name.pluralize
  end

  def plural_class_name
    class_name.pluralize
  end
end
