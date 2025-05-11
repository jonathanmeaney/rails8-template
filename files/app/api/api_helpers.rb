module APIHelpers
  extend Grape::API::Helpers

  Grape::Entity.format_with :date_time_format do |date|
    date&.strftime('%d/%m/%Y %H:%M:%S')
  end

  Grape::Entity.format_with :date_format do |date|
    date&.strftime('%d/%m/%Y')
  end
end
