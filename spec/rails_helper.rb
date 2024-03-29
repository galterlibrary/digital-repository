# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'factory_girl'
require 'active_fedora/cleaner'
require 'devise'
require 'capybara/poltergeist'
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

include Warden::Test::Helpers
Warden.test_mode!

options = {
  js_errors: false,
  phantomjs: Phantomjs.path
}
# Sometimes poltergeist gets transient js errors with no
# reflection in reality.
Capybara.register_driver :poltergeist_no_js_errors do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

# insert `page.driver.debug` into your test to
# launch the WebKit inspector in a browser.
options = options.merge({ inspector: true })
Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.default_max_wait_time = 2

Capybara.javascript_driver = :poltergeist_debug

ActiveRecord::Migration.maintain_test_schema!
RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.include FactoryGirl::Syntax::Methods
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.before :suite do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end

    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :deletion
  end

  config.before :each do |example|
    allow_any_instance_of(Nuldap).to receive(:search).and_return([true, {
      'mail' => ['a@b.c'],
      'displayName' => ['First Last'],
      'eduPersonOrcid' => ['https://orcid.org/0000-9999-9999-9999']
    }])
    allow_any_instance_of(GenericFile).to receive(:check_doi_presence)
    unless (example.metadata[:type] == :view || example.metadata[:no_clean])
      ActiveFedora::Cleaner.clean!
    end

    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
  end

  config.after :each do
    Warden.test_reset!
    DatabaseCleaner.clean
  end
end
