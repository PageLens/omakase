require 'sidekiq/web'
require 'sidetiq/web'
require 'api_constraints'

Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  authenticate :user, lambda { |u| u.admin? or Rails.env.development? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations"}, skip: [:sessions]
  as :user do
    get 'login' => 'devise/sessions#new', :as => :new_user_session
    post 'login' => 'devise/sessions#create', :as => :user_session
    match 'logout' => 'devise/sessions#destroy', :as => :destroy_user_session, :via => [:get, :delete]
  end

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :links
    end
  end

  # get '/', to: 'links#index', as: :links
  # post '/', to: 'links#create'
  get 'r', to: 'redirects#show', as: :redirect
  get 'settings', to: 'settings#edit'
  patch 'settings', to: 'settings#update'
  get 'status', to: 'home#status'
  get 'tools', to: 'home#tools'
  get 'bookmarklet.js', to: 'home#bookmarklet_js', as: :bookmarklet_js, format: :js
  get 'bookmarklet', to: 'home#bookmarklet'
  get 'bmpopup', to: 'home#bookmarklet_popup', as: :bookmarklet_popup
  get 'folders/:folder_id/links', to: 'links#index', as: :folder_links
  get 'links/:link_id/clicks', to: 'clicks#create'

  resources :links do
    collection do
      get 'search'
      get 'bm_save'
    end
    member do
      get 'preview'
    end
    resources :clicks
  end
  resources :bookmark_imports
  resources :feedbacks
  resources :folders do
    resources :sharings
  end
  resources :folder_invitations


  root 'links#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
