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

  catalog_limit_proc = proc { |req| req.env['warden'].user.blank? ? 10 : 500 }
  # Throttle /catalog by subnet
  # 500/6mins for authenticated, 10/6mins for unauthenticated
  # Key: "rack::attack:#{Time.now.to_i/:period}:catalog/subnet:#{subnet of req.ip}"
  throttle('catalog/subnet', limit: catalog_limit_proc, period: 6.minutes) do |req|
    if req.fullpath.start_with?('/catalog?', '/catalog/') && !req.fullpath.start_with?('/catalog?page')
      req.ip.slice(0..req.ip.rindex("."))
    end
  end

  all_limit_proc = proc { |req| req.env['warden'].user.blank? ? 100 : 1000 }
  # Throttle all requests by subnet
  # 1000/6mins for for authenticated, 100/6mins for unauthenticated
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/subnet:#{subnet of req.ip}"
  throttle('req/subnet', limit: all_limit_proc, period: 6.minutes) do |req|
    req.ip.slice(0..req.ip.rindex("."))
  end
end
