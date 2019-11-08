require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
  c.filter_sensitive_data('UA-BOGUS') { ENV['GOOGLE_ANALYTICS_ID'] }
  c.filter_sensitive_data('BOGUS APP') { ENV['GOOGLE_ANALYTICS_APP_NAME'] }
  c.filter_sensitive_data('BOGUS/PATH') { ENV['GOOGLE_ANALYTICS_PRIVKEY_PATH'] }
  c.filter_sensitive_data('BOGUS SECRET') { ENV['GOOGLE_ANALYTICS_PRIVKEY_SECRET'] }
  c.filter_sensitive_data('EMAIL@BOGUS.COM') { ENV['GOOGLE_ANALYTICS_CLIENT_EMAIL'] }
end

RSpec.configure do |c|
  c.before :each, vcr_off: true do
    WebMock.allow_net_connect!
  end

  c.after :each, vcr_off: true do
    WebMock.disable_net_connect!
  end

  c.around :each, vcr_off: true do |ex|
    VCR.eject_cassette
    VCR.turned_off do
      ex.run
    end
  end
end
