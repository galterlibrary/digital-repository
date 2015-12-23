Dir[Rails.root + 'lib/active_fedora/noid/*.rb'].each do |file|
  require file
end
