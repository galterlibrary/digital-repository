require 'byebug'

set :application, 'galter_digital_repo'
set :use_sudo, false
set :format, :pretty
set :log_level, :info # :debug, :error or :info
set :pty, true

# SVC stuff
if ARGV[1] =~ /^deploy/
  puts "Current Branch: #{`git rev-parse --abbrev-ref HEAD`.chomp}"
  puts "Current Tag: #{`git describe --always --tag`.chomp}"
  ask :branch, proc { `git describe --always --tag`.chomp }
end
set :scm, :git
set :ssh_options, { :forward_agent => true }
set :ssh_user, "deploy"
set :repo_url, "git@github.com:galterlibrary/digital-repository.git"
set :deploy_via, :remote_cache

# Paths
set :keep_releases, 5
set :deploy_to, "/var/www/apps/#{fetch(:application)}"
set :linked_dirs, %w{log tmp public/system public/assets solr/default solr/pids public/uploads}
set :linked_files, ['config/local_env.rb', 'config/analytics.yml']

# Rails stuff
set :rvm_ruby_version, 'ruby-2.2.2'
set :bundle_without, %w{development test ci}.join(' ')
set :bundle_flags, "--deployment --path=#{fetch(:deploy_to)}/shared/gems"
set :migration_role, 'migrator'
set :assets_roles, [:web, :app]

set :passenger_environment_variables, {
  path: '/usr/share/gems/gems/passenger-4.0.56/bin:$PATH',
  passenger_tmpdir: '/var/www/apps/tmp'
}
set :passenger_restart_with_sudo, true
# REMOVEME see: https://github.com/capistrano/passenger/issues/33
set :passenger_restart_command,
  'PASSENGER_TMPDIR=/var/www/apps/tmp passenger-config restart-app'

set :fits_zip, '/tmp/fits-0.8.6_1.zip'
set :fits_sh, '/var/www/apps/fits-0.8.6/fits.sh'
set :fits_url,
  'http://projects.iq.harvard.edu/files/fits/files/fits-0.8.6_1.zip'

namespace :config do
  desc 'Create apache config file and add selinux context'
  task :vhost do
    on roles(:web) do
      if fetch(:rails_env) == 'staging'
        www_host_name = 'vtfsmghslrepo01.fsm.northwestern.edu'
      else
        www_host_name = 'digitalhub.northwestern.edu'
      end

      cert_host_name = www_host_name.gsub('.', '_')
      cert_path = '/home/deploy/https_certs'

      vhost_config = StringIO.new(%{
NameVirtualHost *:80
NameVirtualHost *:443

<VirtualHost *:80>
  ServerName #{www_host_name}
  Redirect permanent / https://digitalhub.northwestern.edu/
</VirtualHost>

<VirtualHost *:443>
  ServerName #{www_host_name}
  DocumentRoot #{fetch(:deploy_to)}/current/public

  SSLEngine On
  SSLCertificateFile #{cert_path}/#{cert_host_name}_cert.cer
  SSLCertificateChainFile #{cert_path}/#{cert_host_name}_interm.cer
  SSLCertificateKeyFile #{cert_path}/#{cert_host_name}_key.cer

  #{"RailsEnv staging" if fetch(:rails_env) == 'staging'}
  RailsBaseURI /
  PassengerRuby /usr/local/rvm/wrappers/#{fetch(:rvm_ruby_version)}/ruby
  PassengerFriendlyErrorPages off
  PassengerDebugLogFile /var/log/httpd/#{fetch(:application)}-passenger.log
  PassengerMinInstances 3

  <Directory #{fetch(:deploy_to)}/current/public >
    Options -MultiViews
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
    Order allow,deny
    Allow from all
    # Block Northwestern Google bot, it was hitting us 500/minutes for days
    Deny from 129.105.16.40
  </Directory>
</VirtualHost>

ExpiresActive On
ExpiresByType image/png "access plus 1 month"
ExpiresByType image/gif "access plus 1 month"
ExpiresByType image/jpeg "access plus 1 month"
ExpiresByType text/css "access plus 1 year"
ExpiresByType application/javascript "access plus 1 year"
AddType image/vnd.microsoft.icon .ico
ExpiresByType image/vnd.microsoft.icon "access plus 1 month"

PassengerPreStart https://#{www_host_name}/
      })
      tmp_file = "/tmp/#{fetch(:application)}.conf"
      httpd_file = "/etc/httpd/conf.d/aaa_#{fetch(:application)}.conf"
      upload! vhost_config, tmp_file
      execute :sudo, :mv, tmp_file, httpd_file
      execute :sudo, :chmod, "644", httpd_file
    end
  end

  desc 'Set mail forwarding for the deployment user'
  task :mail_forwarding do
    on roles(:app) do
      load(File.join('config', 'local_env_public.rb'))
      execute "echo #{ENV['SERVER_ADMIN_EMAIL']} > ~/.forward"
    end
  end

  task :install_fits do
    on roles(:app) do
      if !test("[ -f #{fetch(:fits_sh)} ]")
        execute(:curl, fetch(:fits_url), '>', fetch(:fits_zip))
        execute(:unzip, fetch(:fits_zip), '-d' '/var/www/apps')
        execute(:rm, fetch(:fits_zip))
      end
      execute(:chmod, '+x', fetch(:fits_sh))
    end
  end
end

before :deploy, 'config:mail_forwarding'
before :deploy, 'config:install_fits'
after 'deploy:compile_assets', 'deploy:cleanup_assets'
after 'deploy:publishing', 'resque:restart'
after 'deploy:publishing', 'config:vhost'
after 'deploy:publishing', 'deploy:cleanup'
