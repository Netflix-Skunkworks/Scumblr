#     Copyright 2014 Netflix, Inc.
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

Scumblr::Application.routes.draw do

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
    end


  end


  devise_for :users
  resources :users do
    member do
      post 'toggle_admin'
    end
  end




  resources :tags, only: :index

  resources :searches do
    collection do
      get 'options', to: 'providers#options'
      get 'run', to: 'searches#run'
      get :events
    end

    member do
      get 'run', to: 'searches#run'
    end

    member do
      get 'options', to: 'providers#options'
    end
  end


  resources :statuses do
    member do
      post 'set_default'
    end
  end





  get 'status', to: 'status#status'



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
