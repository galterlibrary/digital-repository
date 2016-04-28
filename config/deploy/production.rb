set :stage, :production

set :shib_idp, 'urn:mace:incommon:northwestern.edu'
set :www_host, 'digitalhub.northwestern.edu'
set :rails_env, 'production'
set :ssh_host, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
