require 'logger'

NULL_LOGGER = Logger.new(nil)

GRAPE_REQUEST_LOGGER =
  if Rails.env.test?
    NULL_LOGGER
  else
    Rails.logger
  end
