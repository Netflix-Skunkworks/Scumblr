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

require 'sidekiq/web'

class ActionDispatch::Routing::Mapper
  def draw_custom
    ["custom/config/routes.rb", "../custom/config/routes.rb"].each do |filename|
      instance_eval(File.read(Rails.root.join(filename))) if File.file?(filename)
    end

  end
end

Scumblr::Application.routes.draw do

  draw_custom

  if(User.devise_modules.include?(:omniauthable))
    devise_for :users , :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
    match '/users/auth/openid_connect/callback' => 'users/omniauth_callbacks#openid_connect_callback', via: [:get, :post]
    match '/users/auth/openid_connect' => 'users/omniauth_callbacks#openid_connect', via: [:get, :post], as: "openid_connect"
  else
    devise_for :users
  end

  resources :users do
    member do
      post 'toggle_admin'
    end
  end

  resources :system_metadata do
    member do
      get 'autocomplete', xhr: :get
    end
  end

  resources :events, only: [:index, :show] do
    collection do
      post 'search' => 'events#index'
      get 'search' => 'events#index'
    end

  end
  resources :flags

  get "user_saved_filters/create"
  get "user_saved_filters/destroy"
  get "saved_filters/new"
  get "saved_filters/destroy"

  resources :saved_filters do
    member do
      post :add
      post :remove
    end
  end



  resources :results do
    collection do
      post 'update_multiple'
      post 'bulk_add'
      post 'search' => 'results#index'
      get 'search' => 'results#index'
      get 'tags/:tag', to: 'results#index', as: :tag
      get 'dashboard'
      get 'workflow_autocomplete'
      post 'update_table_columns'

      get 'expandall', to: 'results#expandall'
      get 'show', to: 'results#show', as: :show_by_name
      get 'expandvulns', to: 'results#expandvulns'
      get 'expandclosedvulns', to: 'results#expandclosedvulns'
      post 'create_vulnerability', to: 'results#create_vulnerability'
    end

    member do
      post 'change_status/:status_id'=>"results#update_status", as: 'update_status'
      post 'comment'  => 'results#comment', :as=> :comment
      post 'tag'  => 'results#tag'
      post 'flag'  => 'results#flag'
      post 'action/:result_flag_id/step/:stage_id'  => 'results#action', as: 'action'
      post 'assign'  => 'results#assign'
      post 'subscribe'  => 'results#subscribe'
      post 'unsubscribe'  => 'results#unsubscribe'
      delete 'tags/:tag_id', to: 'results#delete_tag', as: :delete_tag
      post :add_attachment
      delete 'attachment/:attachment_id', to: 'results#delete_attachment', as: :delete_attachment
      post 'generate_screenshot' => "results#generate_screenshot"
      post 'update_screenshot'
      get 'update_screenshot'
      match 'update_metadata', via: [:get, :post]
      match 'get_metadata', via: [:get, :post]
      get 'summary', to: 'results#summary'

      match 'render_metadata_partial', via: [:get, :post]
    end


  end

  resources :tags, only: :index

  resources :tasks do
    collection do
      get 'options', to: 'task_types#options'
      get 'run', to: 'tasks#run'
      post 'bulk_update'
      post 'schedule'
      get 'expandall', to: 'tasks#expandall'
      get 'search', to: 'tasks#search'
      get :events
    end


    member do
      get 'run', to: 'tasks#run'
      post 'run', to: 'tasks#run'
      get 'get_metadata'
      post 'enable', to: 'tasks#enable'
      post 'disable', to: 'tasks#disable'
      get 'summary', to: 'tasks#summary'
      get 'options', to: 'task_types#options'
      get 'on_demand_options', to: 'task_types#on_demand_options'
    end
  end

  resources :statuses do
    member do
      post 'set_default'
    end
  end

  get 'status', to: 'status#status'
  get 'about', to: 'status#about'

  root to: "results#index"

  admin_constraint = lambda do |request|
    request.env['warden'].authenticate? && request.env['warden'].user.admin?
  end

  constraints admin_constraint do
    mount Workflowable::Engine => "/workflowable", as: :workflowable
    mount Sidekiq::Web => '/sidekiq'
    get 'errors', :to => "event_groups#index"
    get 'about', to: 'status#about'
  end

end
