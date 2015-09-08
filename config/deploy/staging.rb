set :stage, :staging

set :rails_env, 'staging'
set :ssh_host, %W{#{fetch(:ssh_user)}@vtfsmghslrepo01.fsm.northwestern.edu}
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
