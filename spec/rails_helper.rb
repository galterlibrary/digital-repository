# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'factory_girl'

ActiveRecord::Migration.maintain_test_schema!

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.include FactoryGirl::Syntax::Methods
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

   config.before :each do |example|
     unless (example.metadata[:type] == :view || example.metadata[:no_clean])
       ActiveFedora::Cleaner.clean!
     end
   end
end
