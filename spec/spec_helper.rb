require 'bundler/setup'
require 'pry'

Bundler.setup

require 'structish'
require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
