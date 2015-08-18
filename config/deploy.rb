set :application, 'galter_digital_repo'
set :use_sudo, false
set :format, :pretty
set :log_level, :debug
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
set :linked_dirs, %w{log tmp public/system public/assets solr/default solr/pids}
set :db_backup_dir, "/home/#{fetch(:ssh_user)}/db_backup"

# Rails stuff
set :rvm_ruby_version, 'ruby-2.2.2'
set :bundle_without, %w{development test ci}.join(' ')
set :bundle_flags, "--deployment --path=#{fetch(:deploy_to)}/shared/gems"
set :migration_role, 'migrator'

namespace :deploy do
  desc 'Precompile assets locally and copy to the remote server'
  task :assets do
    branch = %x(git rev-parse --abbrev-ref HEAD).chomp
    tag = %x(git describe --always --tag).chomp
    if [branch, tag].include?(fetch(:branch)) && !(ENV['ASK_ASSETS'] == 'true')
      set(:confirm_branch, 'yes')
    else
      puts "Assets will be compiled against the current branch: [#{branch}], OK?"
      ask(:confirm_branch, "yes/abort/skip")
    end

    if fetch(:confirm_branch) == 'yes'
      sh %{ RAILS_ENV=production bundle exec rake assets:precompile }
      ssh = "#{fetch(:ssh_user)}@#{primary(:app).hostname}"
      destination = "#{release_path}/public/assets/"
      sh %{ rsync --recursive --times --rsh=ssh --compress --human-readable \
                  --progress --delete --no-p public/assets/ #{ssh}:#{destination} }
      sh %{ bundle exec rake assets:clean }
    elsif fetch(:confirm_branch) == 'abort'
      raise 'Aborting the process, please switch to the proper branch before re-running'
    end
  end

  desc 'block search crawlers with robots.txt (for non production environments)'
  task :block_search_crawlers do
    on roles(:app) do
      within release_path do
        execute :cp, 'public/robots.exclude.txt', 'public/robots.txt'
      end
    end
  end
end

namespace :config do
  desc "Make sure that global RVM doesn't go crazy trying to create gemset dir"
  task :rvm_gemset do
    on roles(:app) do
      gemset_path = "/usr/local/rvm/gems/#{fetch(:rvm_ruby_version)}@galter-website"
      execute :sudo, :mkdir, "-p", gemset_path
    end
  end

  desc 'Configure Postgres'
  task :configure_pg do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, "config", "build.pg", "--with-pg-config=/usr/pgsql-9.3/bin/pg_config"
        end
      end
    end
  end

  desc 'Create database backup directories'
  task :db_backup_tasks do
    on roles(:app) do
      execute :mkdir, '-p', fetch(:db_backup_dir)
      execute :gpg, '--keyserver', 'pgp.mit.edu', '--recv-keys', '3B421A60'
    end
  end

  desc 'Link the file with secrets'
  task :env_file do
    on roles(:app) do
      execute :ln, '-sf', '/etc/ghsl_apps_local_env.rb', "#{release_path}/config/local_env.rb"
    end
  end

  desc 'Create apache config file and add selinux context'
  task :vhost do
    on roles(:web) do
      www_host_name = 'galter-repo.northwestern.edu'
      www_host_name.prepend('www-stage.') if fetch(:rails_env) == 'staging'

      vhost_config = StringIO.new(%{
NameVirtualHost *:80
NameVirtualHost *:443

<VirtualHost *:80>
  ServerName #{www_host_name}
  DocumentRoot #{fetch(:deploy_to)}/current/public

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
    Deny from 91.207.5.186
    Deny from 91.207.7.133
    Deny from 193.201.224.0/22
    Deny from 195.211.152.0/22
    Deny from 54.225.84.134
    Deny from 54.225.115.73
    Deny from 165.20.110.38
    Deny from 23.21.233.232
    Deny from 36.248.171.61
    Deny from 175.44.59.59
    Deny from 112.5.236.125
    Deny from 208.117.13.254
    Deny from 195.154.166.14
    Deny from 165.20.110.48
    # 01/26/2015
    Deny from 198.100.146.30
    Deny from 199.187.127.10
    Deny from 94.23.205.126
    Deny from 112.111.191.13
    Deny from 175.42.93.106
    Deny from 175.42.93.61
    Deny from 59.60.121.65
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

PassengerPreStart http://#{www_host_name}/
      })
      tmp_file = "/tmp/#{fetch(:application)}.conf"
      httpd_file = "/etc/httpd/conf.d/#{fetch(:application)}.conf"
      upload! vhost_config, tmp_file
      execute :sudo, :mv, tmp_file, httpd_file
      execute :sudo, :chmod, "644", httpd_file
      execute :sudo, :chcon, "-t", "httpd_config_t", httpd_file
    end
  end

  desc 'Set mail forwarding for the deployment user'
  task :mail_forwarding do
    on roles(:app) do
      load(File.join('config', 'local_env_public.rb'))
      execute "echo #{ENV['SERVER_ADMIN_EMAIL']} > ~/.forward"
    end
  end
end

before :deploy, 'config:mail_forwarding'
before :deploy, 'config:rails_logrotation'
before :deploy, 'config:rvm_gemset'
before :deploy, 'config:bcdb_path'
before :deploy, 'config:configure_pg'
before :deploy, 'config:db_backup_tasks'
before 'deploy:migrate', 'config:env_file'
before 'deploy:migrate', 'deploy:assets'
after 'deploy:publishing', 'config:vhost'
after 'deploy:publishing', 'httpd:restart'
after 'deploy:publishing', 'deploy:cleanup'
