require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
  c.filter_sensitive_data('BOGUS') { ENV['DATACITE_PASSWORD'] }
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
