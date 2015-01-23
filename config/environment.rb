# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Load non-secret environment vars
load(File.join(Rails.root, 'config', 'local_env_public.rb'))

# Load secret environment vars from local file if it exists
local_env = File.join(Rails.root, 'config', 'local_env.rb')
load(local_env) if File.exists?(local_env)

unless Rails.env.test? || Rails.env.ci?
  if ['LDAP_PASSWORD'].any? {|v| ENV[v].blank? }
    vars = ['LDAP_PASSWORD'].select {|v| ENV[v].blank? }
    $stderr.puts "Can't start Rails. Missing critical env variables: #{vars}"
    ActionMailer::Base.mail(
      from: ENV['DEFAULT_EMAIL_SENDER'],
      to: ENV['SERVER_ADMIN_EMAIL'],
      subject: "Couldn't start Rails on #{ENV['HOSTNAME']}",
      body: "Missing critical env variables: #{vars}"
    ).deliver
    raise SystemExit.new(1)
  end
end

# Initialize the Rails application.
Rails.application.initialize!
