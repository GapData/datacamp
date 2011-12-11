set :default_environment, { 'PATH' => "/usr/local/bin:/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH" }

set :application, "datanest"
set(:deploy_to) { "/home/datanest/rails/#{application}/production" }
server "46.231.96.101", :app, :web, :db, :primary => true

# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

require "delayed/recipes"
set :rails_env, "production" #added for delayed job
# Delayed Job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"