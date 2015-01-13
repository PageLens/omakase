require "pry"
# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'omakase'
set :repo_url, 'git@github.com:PageLens/omakase.git'
set :templates_path, 'config/deploy/templates'
set :sidekiq_timeout, 30

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :default_env, lambda {{
  rails_env: fetch(:stage),
  redis_url: "redis://#{fetch(:redis_host)}/0",
  elasticsearch_url: "http://#{fetch(:search_host)}:9200"
}}

# Default value for keep_releases is 5
set :keep_releases, 5
set :rvm1_ruby_version, '2.1.5'
set :user, 'deploy'
set :pg_password, 'password1234'
set :sidekiq_role, :worker


# Helper functions
def sudo_upload!(from, to)
  filename = File.basename(to)
  to_dir = File.dirname(to)
  tmp_file = "#{fetch(:tmp_dir)}/#{filename}"
  upload! from, tmp_file
  sudo :mv, tmp_file, to_dir
end

def template(template_name)
  config_file = "#{fetch(:templates_path)}/#{template_name}"
  StringIO.new(ERB.new(File.read(config_file)).result(binding))
end

namespace :sidekiq do
  desc 'Generate upstart scripts'
  task :generate_upstart do
    on roles :worker do
      sudo_upload! template('sidekiq.conf.erb'), "/etc/init/sidekiq.conf"
      sudo_upload! template('sidekiq-manager.conf.erb'), "/etc/init/sidekiq-manager.conf"
      sudo_upload! template('sidekiq.etc.conf.erb'), "/etc/sidekiq.conf"
    end
  end
end

namespace :postgresql do
  desc 'Generate database.yml'
  task :generate_database_yml do
    on roles :all do
      next if test "[ -e #{database_yml_file} ]"
      execute :mkdir, '-pv', shared_path.join('config')
      upload! pg_template('postgresql.yml.erb'), database_yml_file
    end
  end

  desc 'Alter DB user to superuser'
  task :alter_db_user_to_superuser do
    on roles :db do
      unless psql '-c', %Q{"ALTER user #{fetch(:pg_user)} WITH SUPERUSER;"}
        error 'postgresql: altering database user failed!'
        exit 1
      end
    end
  end
end

# namespace :deploy do
#
#   desc 'Restart application'
#   task :restart do
#     on roles(:app), in: :sequence, wait: 5 do
#       # Your restart mechanism here, for example:
#       # execute :touch, release_path.join('tmp/restart.txt')
#     end
#   end
#
#   after :publishing, :restart
#
#   after :restart, :clear_cache do
#     on roles(:web), in: :groups, limit: 3, wait: 10 do
#       # Here we can do anything such as:
#       # within release_path do
#       #   execute :rake, 'cache:clear'
#       # end
#     end
#   end
#
# end

namespace :packages do
  desc 'Install packages'
  task :install do
    on roles(:all) do
      with debian_frontend: :noninteractive do
        sudo 'apt-get', 'update'
        sudo 'apt-get', '-y install wget'
        sudo :echo, '"deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list'
        sudo 'apt-get', 'update'
        sudo 'apt-get', '-y --force-yes install git-core curl python-software-properties ufw postgresql-client-9.3 libpq-dev build-essential openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison postfix monit'
      end
    end
  end


  task :install_elasticsearch do
    on roles(:search) do
      execute :wget, '-qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -'
      execute :echo, '"deb http://packages.elasticsearch.org/elasticsearch/1.3/debian stable main" | sudo tee /etc/apt/sources.list.d/elasticsearch.list'
      sudo 'apt-get', 'update'
      sudo 'apt-get', '-y install elasticsearch'
      sudo 'update-rc.d', 'elasticsearch defaults 95 10'
      sudo 'service', 'elasticsearch start'
    end
  end
  after :install, :install_elasticsearch

  task :install_jdk do
    on roles(:search) do
      # Use Oracle JRE
      # sudo 'add-apt-repository', '-y ppa:webupd8team/java'
      # sudo 'apt-get', 'update'
      # sudo 'apt-get', '-y --force-yes install oracle-java7-installer'
      # sudo 'update-alternatives', '--set java /usr/lib/jvm/java-7-oracle/jre/bin/java'

      # Use Open JDK
      sudo 'apt-get', '-y --force-yes install openjdk-7-jdk'
      sudo 'update-alternatives', '--set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java'
    end
  end
  before :install_elasticsearch, :install_jdk

  task :install_postgresql do
    on roles(:db) do
      execute :wget, '-qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -'
      execute :echo, '"deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list'
      sudo 'apt-get', 'update'
      sudo 'apt-get', '-y install postgresql-9.3 postgresql-contrib'
      sudo :sed, %Q{-i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf}
      sudo :sed, '-i "s/host    all             all             127.0.0.1\/32/host    all             all             all/" /etc/postgresql/9.3/main/pg_hba.conf'
      sudo :service, 'postgresql restart'
    end
  end
  after :install, :install_postgresql

  task :install_nginx do
    on roles(:web) do
      sudo 'add-apt-repository', '-y ppa:nginx/stable'
      sudo 'apt-get', 'update'
      sudo 'apt-get', '-y install nginx geoip-database'
      execute :wget, 'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz'
      execute :gunzip, 'GeoLiteCity.dat.gz'
      sudo :cp, 'GeoLiteCity.dat /usr/share/GeoIP/'
    end
  end
  after :install, :install_nginx

  task :install_redis do
    on roles(:redis) do
      sudo 'add-apt-repository', '-y ppa:rwky/redis'
      sudo 'apt-get', 'update'
      sudo 'apt-get', 'install -y redis-server'
      # sudo 'service', 'redis-server restart'
    end
  end
  after :install, :install_redis

  after :install, 'rvm1:install:rvm'
end

before 'setup', 'rvm1:install:ruby'
after 'postgresql:create_db_user', 'postgresql:alter_db_user_to_superuser'
