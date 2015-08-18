set :stage, :production

set :rails_env, 'production'
role :app, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
role :web, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
role :migrator, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
role :production, %W{#{fetch(:ssh_user)}@vfsmghslrepo01.fsm.northwestern.edu}
