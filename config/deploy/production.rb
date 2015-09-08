set :stage, :production

set :rails_env, 'production'
role :ssh_host, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
