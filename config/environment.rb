# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Load non-secret environment vars
load(File.join(Rails.root, 'config', 'local_env_public.rb'))

# Load secret environment vars from local file if it exists
local_env = File.join(Rails.root, 'config', 'local_env.rb')
load(local_env) if File.exists?(local_env)

unless Rails.env.test? || Rails.env.ci?
  vars = ['LDAP_PASS',
          'LDAP_USER',
          'FEDORA_USER',
          'FEDORA_PASS',
          'DB_NAME',
          'DB_USER',
          'DB_PASS'].select {|v| ENV[v].blank? }
  if vars.present?
    $stderr.puts "Can't start Rails. Missing critical env variables: #{vars}"
    ActionMailer::Base.mail(
      from: ENV['DEFAULT_EMAIL_SENDER'],
      to: ENV['SERVER_ADMIN_EMAIL'],
      subject: "Couldn't start Rails on #{`hostname`}, env: #{Rails.env}",
      body: "Missing critical env variables: #{vars}"
    ).deliver
    raise SystemExit.new(1)
  end
end

# Initialize the Rails application.
Rails.application.initialize!
