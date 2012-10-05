require 'rubygems'
require 'bundler'

Bundler.setup

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require "rails/test_help"

#ActionMailer::Base.delivery_method = :test
#ActionMailer::Base.perform_deliveries = true
#ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

require 'shoulda'

# Configure capybara for integration testing
require "capybara/rails"
Capybara.default_driver = :rack_test
Capybara.default_selector = :css

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class AuditLog < ActiveRecord::Base
  attr_accessible :created_at, :updated_at,
    :answer, :action, :question, :article_id, :ip, :user_agent
end