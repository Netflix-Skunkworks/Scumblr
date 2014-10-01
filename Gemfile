source 'https://rubygems.org'

gem 'rails', '4.0.9'


#Support for attr_accessible
#gem 'protected_attributes'

#For Search Providers
gem 'google-api-client'
gem 'twitter'
gem 'koala'

#Database gems
gem 'sqlite3'
gem 'pg'

#OneLogin Authenticatable
#gem 'devise_saml_authenticatable'
#gem 'ruby-saml'
gem 'omniauth-saml'

#Workflow
gem 'workflowable'

#JIRA Integration
#gem 'jira-ruby', require: "jira"
gem 'jiralicious'

#Authorization
gem 'cancan'

#Searching
gem 'ransack'

#market search
gem 'market_bot'
#Image processing/attachments
gem 'paperclip'
gem 'aws-sdk'


#Nice select fields
gem "select2-rails"

#Faster json parsing
gem 'oj'

#Bulk edits
gem 'activerecord-import'

#Used for task queueing
gem 'sidekiq'
gem 'sidekiq-status'

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

#Comments
gem 'acts_as_commentable_with_threading'

#JSON API Calls
gem "active_model_serializers"


#gem 'active_scaffold'
gem "therubyracer"
gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
gem 'simple_form'
gem 'foundation-rails'
#gem 'jquery-datatables-rails', git: 'git://github.com/rweng/jquery-datatables-rails.git'
gem 'unicorn'
gem 'unicorn-rails'
gem 'ip'

group :development do
  gem 'quiet_assets'
  gem "ruby-prof"
  gem "better_errors"
  gem 'meta_request'
  gem "binding_of_caller"
  gem "bullet"
  #gem 'rails-footnotes'
  #gem 'rails-footnotes', github: 'josevalim/rails-footnotes', branch: 'release-4.0'
  gem 'rails-footnotes', '>= 4.0.0', '<5'
  gem 'railroady'
  gem 'ruby_gntp'
  gem 'pry'

end

#Testing
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'

end

group :test do
  #gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  #gem 'selenium-webdriver'
  gem "capybara"
  gem "guard-rspec", "~> 4.2.8"
  gem 'shoulda'
  gem 'activerecord-nulldb-adapter'
end


# Gems used only for assets and not required
# in production environments by default.
# Removed 4.0 group :assets do
##gem 'sass-rails'
##gem 'coffee-rails'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
#gem 'therubyracer', :platforms => :ruby
gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'


gem 'uglifier'
# Remove 4.0 end

gem 'jquery-rails'

gem 'rb-readline'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
