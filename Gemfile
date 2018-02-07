source 'https://rubygems.org'

gem 'rails', '4.2.10'

gem 'zip'
gem 'lograge'
# Allow using posix-spawn for popen to save memory with multiple threads.
gem 'posix-spawn'

#For Tasks/Search Providers
gem 'google-api-client', '~>0.8.0'
gem "github_api", require: false
gem 'colorize', require: false
gem 'twitter'
gem 'market_bot'
gem 'koala'
gem "brakeman", require: false
gem "bundler-audit"
gem 'rest-client'
gem 'chartkick'
gem 'redcarpet'

gem 'addressable'

gem 'jwt', '<= 1.5.2'

# Pretty file sizes
gem 'filesize'

# scott things
gem 'json-schema-generator'
gem 'zeroclipboard-rails'

gem 'activerecord-session_store', git: 'https://github.com/rails/activerecord-session_store'
#Database gems
gem 'sqlite3'
gem 'pg'

#git functionality
gem 'git'

#Workflow
gem 'workflowable'

#JIRA Integration
#gem 'jiralicious'
gem 'jira-ruby'
#Authorization
gem 'cancan'

#Searching
gem 'ransack'

#Image processing/attachments
gem 'paperclip', ">= 5.0"
gem 'aws-sdk'
gem 'aws-sdk-ses'

# Time period parsing
gem 'chronic'

#Nice select fields
gem "select2-rails"

#Faster json parsing
gem 'oj'

#Bulk edits
gem 'activerecord-import'

#Used for task queueing
gem 'sidekiq'
gem 'sidekiq-status'
gem 'sidekiq-scheduler'
gem 'sidekiq-limit_fetch'
gem 'mlanett-redis-lock', require: 'redis-lock'

#Pagination
gem 'kaminari'

#Sidekiq UI
gem 'sinatra', require: false

#Templating language, not sure if used
gem 'slim'

#Performance gem that changes how links are handed
##gem 'turbolinks'
gem 'jquery-turbolinks'

#Allowing exporting/importing data into database
gem 'yaml_db'

#Authentication
gem 'devise'
gem 'responders'

#Comments
gem 'acts_as_commentable_with_threading'

#JSON API Calls
gem "active_model_serializers"

# Cron job generation
gem "whenever"

# Used for finding changes to serialized attributes
gem "hashdiff"

#gem 'active_scaffold'
gem "therubyracer"
gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
gem 'simple_form'

gem 'ip'

gem 'stackprof'

gem 'faraday'
gem 'net-http-persistent'

gem 'minitest'

gem 'minitest-rails'

group :development, :test, :production do
  gem 'unicorn'
  gem 'unicorn-rails'
end

group :test do
  #this doesn't get along with rack-mini-profiler
  gem 'oj_mimic_json'
end

# Used for Redis Cache
gem "redis-store", ">= 1.4.1"
gem "redis-rails"

group :development, :dirtylaundrydev do
  gem 'spring', group: :development
  gem "ruby-prof"
  gem 'meta_request'
  gem "binding_of_caller"
  gem "bullet"
  gem 'rack-mini-profiler', require: false
  gem 'flamegraph'
  gem 'rbtrace'
  #gem 'rails-footnotes'
  #gem 'rails-footnotes', github: 'josevalim/rails-footnotes', branch: 'release-4.0'
  gem 'rails-footnotes', '>= 4.0.0', '<5'
  gem 'railroady'
  gem 'ruby_gntp'
  # gem 'rack-perftools_profiler', :require => 'rack/perftools_profiler'
end

group :development, :dirtylaundrydev, :profile do

  gem 'byebug'
  gem 'quiet_assets'
  gem "better_errors"
  gem 'pry'

end

#Testing
group :development, :test, :dirtylaundrydev do
  #gem 'rspec-rails'
  gem 'factory_girl_rails'

end

group :test do
  gem 'database_cleaner'
  gem 'shoulda', '~> 3.5'
  gem 'activerecord-nulldb-adapter'
  gem 'minitest-reporters'
  gem 'shoulda-matchers', '~> 2.0'
  gem 'shoulda-callback-matchers', '~> 1.1.1'
  gem 'simplecov', :require => false, :group => :test
end

gem 'foundation-rails', '5.3.3.0'
gem 'sass-rails',   '5.0.7'
gem 'sass', '3.2.19'
gem 'coffee-rails', '4.0.1'
gem 'sprockets', '2.11.3'


gem 'uglifier'

gem 'jquery-rails'

gem 'rb-readline'

gem 'crack', '0.3.2'

# needed by  sidekiq
gem 'json'
gem 'ffi'


if File.exists?("custom/Gemfile")
  eval(IO.read("custom/Gemfile"), binding)
end
if File.exists?("../custom/Gemfile")
  eval(IO.read("../custom/Gemfile"), binding)
end
if File.exists?("./Gemfile.append")
  eval(IO.read("./Gemfile.append"), binding)
end
