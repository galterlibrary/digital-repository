class Rack::Attack
  # cache store
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # whitelist NU network
  safelist_ip("165.124.0.0/16")
  safelist_ip("129.105.0.0/16")

  # Always allow requests from localhost
  # (blocklist & throttles are skipped)
  Rack::Attack.safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # These include some requests by the application, and not by the user
  Rack::Attack.safelist('ignorable paths') do |req|
    req.fullpath.start_with?('/assets',
                             '/users/notifications_number', 
                             '/catalog/facet/tags_sim.json',
                             '/downloads/')
  end

  # Allow authenticated user
  Rack::Attack.safelist('authenticated user') do |req|
    !req.env['warden'].user.blank?
  end

  # Based on occurrences during the week of June 16, 2019, DigitalHub
  # suffered a DDoS-like event. Inspection of logs during the event showed
  # +10k requests per hour to digitalhub, from thousands of different ips.
  # Throttling by ip would prove ineffective in this case. Though in the
  # hundreds, the ips showed a subnet-like pattern. The following throttle
  # rules, tracking by subnet, are based off this event.

  # Throttle /catalog by subnet
  # Exponential Backoff for unauthenticated user
  #   Level 6: 96 requests per 64 minutes
  #   Level 7: 112 requests per 128 minutes
  #   Level 8: 128 requests per 256 minutes
  #   Level 9: 144 requests per 512 minutes
  #   Level 10: 160 requests per 1024 minutes
  (6..10).each do |level|
    # We set a strict limit for the catalog path because facets/filters consume
    # a lot of resources, hence slowing down digitalhub. Navigating around the
    # '/catalog?page' path is fine.
    throttle("catalog/subnet/#{level}", :limit => (16 * level), :period => (2 ** level).minutes) do |req|
      if req.fullpath.start_with?('/catalog?', '/catalog/') && !req.fullpath.start_with?('/catalog?page')
        req.ip.slice(0..req.ip.rindex("."))
      end
    end
  end

  # Throttle all requests by subnet for unauthenticated user
  throttle('req/subnet', limit: 1000, period: 1.hour) do |req|
    req.ip.slice(0..req.ip.rindex("."))
  end

  # Custom throttle response
  self.throttled_response = lambda do |env|
    [
      503, # status
      {}, # headers
      ['Looks like you have reached your limit. ',
       'Please log in to get the full experience.'] # body
    ]
  end
end
