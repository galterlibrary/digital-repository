Rails.configuration.middleware.use Browser::Middleware do
  if browser.mobile? &&
      request.get? &&
      request.path =~ /^\/collections\/[1-9a-zA-Z]+/ &&
      request.fullpath !~ /view=gallery/ &&
      request.path !~ /^\/collections\/[1-9a-zA-Z]+\/edit/ &&
      request.path !~ /^\/collections\/[1-9a-zA-Z]+\/new/
    request.update_param('view', 'gallery')
  end
end
