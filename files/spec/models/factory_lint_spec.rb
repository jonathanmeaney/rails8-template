require 'rails_helper'

RSpec.describe 'FactoryBot' do
  it 'lints factories' do
    FactoryBot.lint(traits: true)
  end
end
