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
set :ssh_user_home, "/home/#{fetch(:ssh_user)}"
set :repo_url, "git@github.com:galterlibrary/digital-repository.git"
set :deploy_via, :remote_cache

load 'config/local_env.rb'
set :slackistrano, {
  channel: '#general',
  webhook: ENV['SLACK_HOOK']
}

# Paths
set :keep_releases, 5
set :deploy_to, "/var/www/apps/#{fetch(:application)}"
set :linked_dirs, %w{log tmp public/system public/assets solr/default solr/pids public/uploads}
set :linked_files, [
  'config/local_env.rb',
  'config/analytics.yml',
  'config/browse_everything_providers.yml'
]

# Rails stuff
set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.3.7'
set :rvm_ruby_path, "#{fetch(:ssh_user_home)}/.rvm/wrappers/#{fetch(:rvm_ruby_version)}/ruby"
set :passenger_version, '5.2.3'
set :rvm_ruby_gems_version, '2.3.0'
set :passenger_dir, "#{fetch(:deploy_to)}/shared/gems/ruby/#{fetch(:rvm_ruby_gems_version)}/gems/passenger-#{fetch(:passenger_version)}"
set :bundle_without, %w{development test ci}.join(' ')
set :bundle_flags, "--deployment --path=#{fetch(:deploy_to)}/shared/gems"
set :migration_role, 'migrator'
set :assets_roles, [:web, :app]
set :whenever_roles, :all

set :fits_version, '1.0.3'
set :fits_zip, "/tmp/fits-#{fetch(:fits_version)}.zip"
set :fits_libmedia, "/var/www/apps/fits-#{fetch(:fits_version)}/tools/mediainfo/linux"
set :fits_sh, "/var/www/apps/fits-#{fetch(:fits_version)}/fits.sh"
set :fits_env, "/var/www/apps/fits-#{fetch(:fits_version)}/fits-env.sh"
set :fits_url,
  "http://projects.iq.harvard.edu/files/fits/files/fits-#{fetch(:fits_version)}.zip"

namespace :config do
  desc 'Create apache config file and add selinux context'
  task :vhost do
    on roles(:web) do
      cert_host_name = fetch(:www_host).gsub('.', '_')
      cert_path = '/home/deploy/https_certs'

      vhost_config = StringIO.new(%{
<VirtualHost *:80>
  UseCanonicalName On
  ServerName #{fetch(:www_host)}
  Redirect permanent / https://#{fetch(:www_host)}/
</VirtualHost>

<VirtualHost *:443>
  UseCanonicalName On
  ServerName #{fetch(:www_host)}
  DocumentRoot #{fetch(:deploy_to)}/current/public

  SSLEngine On
  SSLCertificateFile #{cert_path}/#{cert_host_name}_cert.cer
  SSLCertificateChainFile #{cert_path}/#{cert_host_name}_interm.cer
  SSLCertificateKeyFile #{cert_path}/#{cert_host_name}_key.cer

  #{"RailsEnv staging" if fetch(:rails_env) == 'staging'}
  RailsBaseURI /
  PassengerFriendlyErrorPages off
  PassengerMinInstances 3
  PassengerRuby #{fetch(:rvm_ruby_path)}

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

PassengerPreStart https://#{fetch(:www_host)}/
      })
      tmp_file = "/tmp/#{fetch(:application)}.conf"
      httpd_file = "/etc/httpd/conf.d/aaa_#{fetch(:application)}.conf"
      upload! vhost_config, tmp_file
      execute :sudo, :mv, tmp_file, httpd_file
      execute :sudo, :chmod, "644", httpd_file
    end
  end
  
  desc 'Install passenger apache'
  task :install_passenger_apache do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          if ENV['INSTALL_PASS_APACHE'] == 'true'
            puts "INSTALLING Passenger Apache"
            options = ['--auto']
            
            execute('bundle', 'exec', 'passenger-install-apache2-module', *options)
          else
            puts "SKIPPING Passenger Apache Installation(config:install_passenger_apache)"
            puts "Run with INSTALL_PASS_APACHE=true in the environment to enable"
          end
        end
      end
    end
  end
  
  desc 'Set up passenger.conf'
  task :set_up_passenger_conf do
    on roles(:web) do
      if ENV['INSTALL_PASS_APACHE'] == 'true' || ENV['CONF_PASS_APACHE'] == 'true'
        puts "SETTING UP passenger.conf"
        passenger_config = StringIO.new(%{
LoadModule passenger_module #{fetch(:passenger_dir)}/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot #{fetch(:passenger_dir)}
  PassengerDefaultRuby #{fetch(:rvm_ruby_path)}
  PassengerLogFile /var/log/#{fetch(:application)}-passenger.log
  PassengerInstanceRegistryDir /tmp
</IfModule>
          })
        tmp_file = '/tmp/passenger.conf'
        passenger_conf_file = '/etc/httpd/conf.d/passenger.conf'
        upload! passenger_config, tmp_file
        execute :sudo, :mv, tmp_file, passenger_conf_file
        execute :sudo, :chmod, '644', passenger_conf_file
      end
    end
  end

  desc 'Create and upload systemd galter-resque.service file'
  task :resque_service_config do
    on roles(:web) do
      resque_service_config = StringIO.new(%{
[Unit]
Description=Galter Resque Service
After=syslog.target
After=network.target

[Service]
Type=forking

User=deploy
Group=deploy

WorkingDirectory=#{fetch(:deploy_to)}/current

Environment="RUN_AT_EXIT_HOOKS=true"
Environment="TERM_CHILD=1"

# This is normally controlled by the global default set by systemd
# StandardOutput=syslog

PIDFile=#{fetch(:deploy_to)}/shared/tmp/pids/resque-pool.pid
ExecStart=/usr/bin/env #{fetch(:ssh_user_home)}/.rvm/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec resque-pool --daemon --environment #{fetch(:rails_env)}
Restart=on-failure
ExecStop=kill -INT `cat #{fetch(:deploy_to)}/shared/tmp/pids/resque-pool.pid`
# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300

[Install]
WantedBy=multi-user.target
      })
      tmp_file = "/tmp/#{fetch(:application)}_galter-resque.service"
      upload! resque_service_config, tmp_file
      execute :sudo, :mv, tmp_file, '/etc/systemd/system/galter-resque.service'
      execute :sudo, :chmod, '644', '/etc/systemd/system/galter-resque.service'
      execute :sudo, :systemctl, 'daemon-reload'
    end
  end

  desc 'Upload Shibboleth related config file'
  task :shib_httpd do
    on roles(:web) do
      local_file = 'config/deploy/shib/shib.conf'
      remote_file = '/etc/httpd/conf.d/shib.conf'
      tmp_file = "/tmp/#{fetch(:application)}_shib.conf"
      upload! local_file, tmp_file
      execute :sudo, :mv, tmp_file, remote_file
      execute :sudo, :chmod, "644", remote_file
    end
  end

  desc 'Create and upload shibboleth2.xml file'
  task :shib_config do
    on roles(:web) do
      shib_config = StringIO.new(%{
<SPConfig xmlns="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    clockSkew="180">

    <ApplicationDefaults entityID="#{fetch(:shib_sp)}"
                         REMOTE_USER="eppn persistent-id targeted-id">

        <Sessions lifetime="28800" timeout="3600" relayState="ss:mem"
                  checkAddress="false" handlerSSL="true" cookieProps="https">

            <SSO entityID="#{fetch(:shib_idp)}">
              SAML2 SAML1
            </SSO>

            <Logout>SAML2 Local</Logout>
            <Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>
            <Handler type="Status" Location="/Status" acl="127.0.0.1 165.124.124.27 ::1"/>
            <Handler type="Session" Location="/Session" showAttributeValues="false"/>
            <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>
        </Sessions>

        <Errors supportContact="deploy@localhost"
            helpLocation="/about.html"
            styleSheet="/shibboleth-sp/main.css"/>

        <MetadataProvider type="XML"
                          path="/etc/shibboleth/nu-idp-metadata.xml"
                          reloadInterval="7200"/>
        <AttributeExtractor type="XML" validate="true" reloadChanges="false" path="attribute-map.xml"/>
        <AttributeResolver type="Query" subjectMatch="true"/>
        <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>
        <CredentialResolver type="File" key="sp-key.pem" certificate="sp-cert.pem"/>
    </ApplicationDefaults>

    <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>
    <ProtocolProvider type="XML" validate="true" reloadChanges="false" path="protocols.xml"/>
</SPConfig>
      })
      tmp_file = "/tmp/#{fetch(:application)}_shib_xml.conf"
      upload! shib_config, tmp_file
      execute :sudo, :mv, tmp_file, '/etc/shibboleth/shibboleth2.xml'
      execute :sudo, :chmod, '644', '/etc/shibboleth/shibboleth2.xml'
      execute :sudo, :cp, '/var/www/apps/shib/nu-idp-metadata.xml',
                          '/etc/shibboleth/nu-idp-metadata.xml'
      execute :sudo, :chmod, '644', '/etc/shibboleth/nu-idp-metadata.xml'
    end
  end

  desc 'Set mail forwarding for the deployment user'
  task :mail_forwarding do
    on roles(:app) do
      load(File.join('config', 'local_env_public.rb'))
      execute "echo #{ENV['TECH_ADMIN_EMAIL']} > ~/.forward"
    end
  end

  task :custom_image_magic_gs do
    on roles(:app) do
      if ENV['IMAGE_MAGIC'] == 'true'
        upload! File.join('config', 'deploy', 'image_magic_gs'), '/tmp/gs_deploy'
        execute :mkdir, '-p', '/home/deploy/bin'
        execute :mv, '/tmp/gs_deploy', '/home/deploy/bin/gs'
        execute(:chmod, '+x', '/home/deploy/bin/gs')
        upload! File.join('config', 'deploy', 'image_magic_delegates.xml'),
          '/tmp/delegates.xml_deploy'
        execute :sudo, :mv, '/tmp/delegates.xml_deploy',
          '/etc/ImageMagick/delegates.xml'
        execute(:sudo, :chmod, '644', '/etc/ImageMagick/delegates.xml')
      else
        puts "!!!Skipping ImageMagic deployment!!!"
        puts "Run with `IMAGE_MAGIC=true' to upload a new version"
      end
    end
  end

  task :install_fits do
    on roles(:app) do
      if !test("[ -f #{fetch(:fits_sh)} ]")
        execute(:curl, fetch(:fits_url), '>', fetch(:fits_zip))
        execute(:unzip, fetch(:fits_zip), '-d' '/var/www/apps')
        execute(:rm, fetch(:fits_zip))
        execute(:echo, "LD_LIBRARY_PATH=#{fetch(:fits_libmedia)}", ">>", fetch(:fits_env))
        execute(:echo, "export LD_LIBRARY_PATH", ">>", fetch(:fits_env))
      end
      execute(:chmod, '+x', fetch(:fits_sh))
    end
  end
end

before :deploy, 'config:mail_forwarding'
before :deploy, 'config:install_fits'
before :deploy, 'config:custom_image_magic_gs'
before 'config:vhost', 'config:install_passenger_apache'
before 'config:vhost', 'config:set_up_passenger_conf'
after 'deploy:compile_assets', 'deploy:cleanup_assets'
after 'deploy:publishing', 'config:resque_service_config'
after 'deploy:publishing', 'resque:restart'
after 'deploy:publishing', 'config:shib_config'
after 'deploy:publishing', 'systemctl:shibd:restart'
after 'deploy:publishing', 'config:vhost'
after 'deploy:publishing', 'config:shib_httpd'
after 'deploy:publishing', 'systemctl:httpd:restart'
