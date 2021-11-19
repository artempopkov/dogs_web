set :application, 'dogs_web'
set :repo_url, 'git@github.com:artempopkov/dogs_web.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :scm is :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('.env', 'config/database.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads', 'public/media')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rails_env, 'production'
set :deploy_to, '/home/deployer/www/dogs_web'

# puma
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :puma_bind, "tcp://167.99.131.238:5000"
set :puma_threads, [0, 5]
set :puma_workers, 2
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true

set :sidekiq_env, 'production'
set :sidekiq_pid, File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
set :sidekiq_log, File.join(shared_path, 'log', 'sidekiq.log')

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
  before :start, 'deploy:migrate'
  before :restart, 'deploy:migrate'
end

desc 'Invoke a rake command on the remote server'
task :invoke, [:command] => 'deploy:set_rails_env' do |task, args|
  on primary(:app) do
    within current_path do
      with :rails_env => fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

namespace :deploy do
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  after :restart, :clear_cache do
    invoke 'puma:restart'
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end

  after :publishing, :restart
  after :finishing, :cleanup
  before :finishing, :restart
  after :rollback, :restart
end

namespace :rails do
  desc 'Open the rails console on each of the remote servers'
  task console: 'rvm:hook' do
    on roles(:app), primary: true do |host|
      execute_interactively host, 'console production'
    end
  end
end

def execute_interactively(host, command)
  command = "cd #{fetch(:deploy_to)}/current && #{SSHKit.config.command_map[:bundle]} exec rails #{command}"
  puts command if fetch(:log_level) == :debug
  exec "ssh -l #{host.user} #{host.hostname} -p #{host.port || 22} -t '#{command}'"
end# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :web, %w{deploy@your ip}
role :app, %w{deploy@your ip}

set :migration_role, :app

set :rvm_ruby_version, '3.0.0@dogs_web'
set :rvm_type, :user
set :branch, :staging

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server '167.99.131.238', user: 'deployer', roles: %w{web app}