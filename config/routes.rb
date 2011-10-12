ProjectLimelight::Application.routes.draw do

  # Pictures
  resources :pictures

  # Videos
  resources :videos

  # News
  resources :news

  # Talk
  resources :talks

  # Feeds
  post 'feeds/update' => 'feeds#update', :as => :feed_update

  # Following
  post   '/follows' => 'follows#create', :as => :create_follow
  delete '/follows' => 'follows#destroy', :as => :destroy_follow
  get    '/follows' => 'follows#index', :as => :user_follows

  # Favoriting
  post   '/favorites' => 'favorites#create', :as => :create_favorite
  delete '/favorites' => 'favorites#destroy', :as => :destroy_favorite
  get    '/:id/favorites/' => 'favorites#index', :as => :user_favorites

  # Voting
  post   '/votes' => 'votes#create', :as => :create_vote
  delete '/votes' => 'votes#destroy', :as => :destroy_vote
  get    '/votes' => 'votes#index', :as => :user_votes

  # Reposting
  post   '/reposts' => 'reposts#create', :as => :create_repost
  delete '/reposts' => 'reposts#destroy', :as => :destroy_repost

  # Embedly
  get 'embed' => 'embedly#show', :as => :embedly_fetch

  # Topics
  resources :topics
  get 't/:id' => 'topics#show', :as => :topic
  get 't/:id/hover' => 'topics#hover' , :as => :topic_hover
  put 't/:id' => 'topics#update', :as => :update_topic

  # Topic Types
  resources :topic_types

  # Notifications
  get '/:id/notifications' => 'notifications#index', :as => :notifications

  # Core Object Shares
  post '/share/create' => 'core_object_shares#create', :as => :create_share

  # Resque admin
  mount Resque::Server, :at => "/resque"

  # Soulmate api
  mount Soulmate::Server, :at => "/soul-data"

  # Uploads
  match "/upload" => "uploads#create", :as => :upload_tmp

  # Users
  devise_for :users
  # Edit and update are temporary to test callbacks on User model
  resources :users, :only => [:show, :edit, :update]
  get ':id/following/users' => 'users#following_users', :as => :user_following_users
  get ':id/following/topics' => 'users#following_topics', :as => :user_following_topics
  get ':id/followers' => 'users#followers', :as => :user_followers
  get ':id/feed' => 'users#feed', :as => :user_feed
  get ':id/hover' => 'users#hover' , :as => :user_hover

  # Home
  root :to => "pages#home"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
