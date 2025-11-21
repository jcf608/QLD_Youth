require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || 'development')

require 'sinatra/base'
require 'sinatra/activerecord'
require 'dotenv/load'

# Configure database
ActiveRecord::Base.establish_connection(
  ENV['DATABASE_URL'] || "postgresql://localhost/qld_youth_#{ENV['RACK_ENV'] || 'development'}"
)

# Require all models
Dir[File.join(__dir__, '../app/models', '*.rb')].each { |file| require file }

