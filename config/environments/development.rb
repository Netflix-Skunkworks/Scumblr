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

Scumblr::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  #config.cache_classes = true
  config.active_record.raise_in_transactional_callbacks = true
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions)
    }
  end

  # Disable automatically joining tables. This was added to prevent Rails from modifying searches on
  # metadata (jsonb) fields using the @> operator. If the right operand contains a dot separated value
  # (example: "test.com") Rails was interpreting this as a table/column and this was breaking the query
  # AH 3/10/16


  # config.middleware.use ::Rack::PerftoolsProfiler, :default_printer => 'gif', :bundler => true

  # Log error messages when you accidentally call methods on nil.
  # config.whiny_nils = true

  #Force raising callback errors
  config.active_record.raise_in_transactional_callbacks = true

  config.eager_load = false
  #config.eager_load = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  #config.action_mailer.default_url_options = { :host => "localhost:3000", :protocol => 'http' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  Rails.application.routes.default_url_options[:host] = "localhost:3000"

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false
  config.assets.compile = true

  # Expands the lines which load the assets
  config.assets.debug = false

  #config.assets.prefix = "/assets_dev"

end

silence_warnings do
  require 'pry'
  IRB = Pry
end
