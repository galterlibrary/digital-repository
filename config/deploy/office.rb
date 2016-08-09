set :stage, :staging

server '192.168.122.71',
        user: 'deploy',
        roles: %w{app db web migrator resque_scheduler resque_worker}
set :ssh_options, {
  proxy: Net::SSH::Proxy::Command.new('ssh deploy@165.124.124.30 -W %h:%p'),
  forward_agent: true,
}

set :rails_env, 'staging'
set :www_host, 'galter-2310-1.fsm.northwestern.edu'
set :shib_idp, 'https://testfed3.ci.northwestern.edu/idp/shibboleth'
set :shib_sp, "https://#{fetch(:www_host)}/shibboleth"
