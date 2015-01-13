set :nginx_server_name, 'pagelens.com'
set :nginx_use_ssl, true
set :nginx_ssl_cert_local_path, "keys/ssl/pagelens.com.crt"
set :nginx_ssl_cert_key_local_path, "keys/ssl/pagelens.key"
set :pg_pool, 30
set :pg_host, '192.168.0.18'
set :redis_host, "192.168.0.18"
set :search_host, '192.168.0.19'
set :sidekiq_processes, 2
set :unicorn_workers, 4

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :app, %w{deploy@38.113.112.17}
role :web, %w{deploy@38.113.112.17}
role :redis, %w{deploy@38.113.112.18}
role :db,  %w{deploy@38.113.112.18}
role :worker, %w{deploy@38.113.112.19}
role :search, %w{deploy@38.113.112.19}

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
#
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
