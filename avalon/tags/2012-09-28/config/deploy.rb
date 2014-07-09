set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'rvm/capistrano'

set :application, "hydrant"
set :repository,  "git://github.com/variations-on-video/hydrant.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :deploy_to, "/srv/rails/hydrant-test"
set :user, "vov"
set :use_sudo, false

#set :rvm_type, :root
set :rvm_ruby_string, 'ruby-1.9.3@hydrant'                     # Or:
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") # Read from local system

task :uname do
  run "uname -a"
end
