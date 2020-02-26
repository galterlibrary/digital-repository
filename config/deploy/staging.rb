set :stage, :staging

set :www_host, 'vtfsmghslrepo01.fsm.northwestern.edu'
set :rails_env, 'staging'
set :ssh_host, %W{#{fetch(:ssh_user)}@#{fetch(:www_host)}}
set :shib_idp, 'https://fed-uat.it.northwestern.edu/idp/shibboleth'
set :shib_sp, "https://#{fetch(:www_host)}/users/auth/shibboleth/callback"
set :shib_metadata, "uat-idp-metadata"
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
