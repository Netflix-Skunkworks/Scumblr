#     Copyright 2016 Netflix, Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.


require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

# Hack to make root path element accessible to allow
# Customizing the locations where files are loaded.
# This allow providing customizations for models,
# controllers, views, etc. that can be stored in a
# location separate from the main Scumblr repo.
module Rails
  module Paths
    class Root
      attr_accessor :root
    end
  end
end

module Scumblr
  class Application < Rails::Application

    ## Setup paths to allow loading customizatoins
    # Create a copy of the original paths
    tmp_root = Rails.configuration.paths.root

    # Create an empty set of paths
    new_root = {}

    # Inject paths for custom models, views and controllers
    ["custom/", "../custom/"].each do |custom_path|
      if Dir.exists?("#{Rails.root.to_s}/#{custom_path}")
        r = Rails::Paths::Root.new("#{Rails.root.to_s}/#{custom_path}")
        ["app/models", "app/controllers", "app/views", "app/workers"].each do |folder|
          new_root[custom_path + folder] = Rails::Paths::Path.new(r, custom_path + folder, [custom_path + folder], {eager_load: true})
        end

      end
    end


    # Merge in original path list
    new_root.merge!(tmp_root)

    # Add paths for custom initializers, environments, and views
    new_root["config/initializers"] << "../custom/config/initializers"
    new_root["config/initializers"] << "custom/config/initializers"
    new_root["config/environments"] << "../custom/config/environments"
    new_root["config/environments"] << "custom/config/environments"
    new_root["app/views"].unshift("custom/app/views")
    new_root["app/views"].unshift("../custom/app/views")


    # Overwrite the original path element
    Rails.configuration.paths.root = new_root


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)


    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'


    config.to_prepare do
      Devise::SessionsController.layout proc{ |controller| action_name == 'new' ? "devise" : "application" }
    end

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    #config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.paths << "#{Rails.root}/app/assets/fonts"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
