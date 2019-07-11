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

  # Based on occurrences during the week of June 16, 2019, DigitalHub
  # suffered a DDoS-like event. Inspection of logs during the event showed
  # +10k requests per hour to digitalhub, from thousands of different ips.
  # Throttling by ip would prove ineffective in this case. Though in the
  # hundreds, the ips showed a subnet-like pattern. The following throttle
  # rules, tracking by subnet, are based off this event.
  catalog_limit_proc = proc { |req| req.env['warden'].user.blank? ? 100 : 5000 }
  # Throttle /catalog by subnet
  # 5000/hr for authenticated, 100/hr for unauthenticated
  throttle('catalog/subnet', limit: catalog_limit_proc, period: 1.hour) do |req|
    if req.fullpath.start_with?('/catalog?', '/catalog/') && !req.fullpath.start_with?('/catalog?page')
      req.ip.slice(0..req.ip.rindex("."))
    end
  end

  all_limit_proc = proc { |req| req.env['warden'].user.blank? ? 1000 : 10000 }
  # Throttle all requests by subnet
  # 10000/hr for for authenticated, 1000/hr for unauthenticated
  throttle('req/subnet', limit: all_limit_proc, period: 1.hour) do |req|
    req.ip.slice(0..req.ip.rindex("."))
  end
end
