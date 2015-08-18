set :stage, :staging

set :rails_env, 'staging'
role :app, %W{#{fetch(:ssh_user)}@vtfsmghslrepo01.fsm.northwestern.edu}
role :web, %W{#{fetch(:ssh_user)}@vtfsmghslrepo01.fsm.northwestern.edu}
role :migrator, %W{#{fetch(:ssh_user)}@vtfsmghslrepo01.fsm.northwestern.edu}
