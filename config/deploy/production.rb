set :stage, :production

set :www_host, 'digitalhub.northwestern.edu'
set :rails_env, 'production'
set :ssh_host, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
set :shib_idp, 'urn:mace:incommon:northwestern.edu'
set :shib_sp, "https://#{fetch(:www_host)}/users/auth/shibboleth/callback"
role :app, fetch(:ssh_host)
role :web, fetch(:ssh_host)
role :migrator, fetch(:ssh_host)
role :resque_worker, fetch(:ssh_host)
role :resque_scheduler, fetch(:ssh_host)
