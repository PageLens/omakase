set :pg_pool, 25
set :pg_host, '10.77.62.147'
set :redis_host, '10.77.62.147'
set :search_host, '10.77.62.147'
set :sidekiq_processes, 1
set :unicorn_workers, 1

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :app, %w{deploy@10.77.62.147}
role :web, %w{deploy@10.77.62.147}
role :redis, %w{deploy@10.77.62.147}
role :db,  %w{deploy@10.77.62.147}
role :worker, %w{deploy@10.77.62.147}
role :search, %w{deploy@10.77.62.147}


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

# server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#  set :ssh_options, {
#    keys: %w(/home/deploy/.ssh/deploy_at_pagelens.net),
#    port: 2202
#   #  forward_agent: false,
#   #  auth_methods: %w(password)
#  }
# #
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
