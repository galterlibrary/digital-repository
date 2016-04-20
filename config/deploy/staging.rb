set :stage, :staging

set :shib_idp, 'https://testfed3.ci.northwestern.edu/idp/shibboleth'
set :www_host, 'vtfsmghslrepo01.fsm.northwestern.edu'
set :rails_env, 'staging'
set :ssh_host, %W{#{fetch(:ssh_user)}@#{fetch(:www_host)}}
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
