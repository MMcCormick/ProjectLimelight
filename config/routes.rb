ProjectLimelight::Application.routes.draw do

  # redirect to example.com if user goes to www.example.com
  match '(*any)' => redirect { |p, req| req.url.sub('www.', '') }, :constraints => { :host => /^www\./ }

  # API
  scope 'api' do
    scope 'users' do
      scope 'follows' do
        post '' => 'follows#create', :type => 'User'
        delete '' => 'follows#destroy', :type => 'User'
      end

      get 'following_users' => 'users#following_users'
      get 'followers' => 'users#followers'
      get 'influence_increases' => 'users#influence_increases'
      post '' => 'users#create'
      get '' => 'users#show'
    end

    scope 'topics' do
      scope 'follows' do
        post '' => 'follows#create', :type => 'Topic'
        delete '' => 'follows#destroy', :type => 'Topic'
      end

      get 'suggestions' => 'topics#suggestions'
      get '' => 'topics#show'
    end

    scope 'posts' do
      post '' => 'posts#create'
      get 'user_feed' => 'posts#user_feed'
      get 'like_feed' => 'posts#like_feed'
      get 'activity_feed' => 'posts#activity_feed'
      get 'topic_feed' => 'posts#topic_feed'
      get 'friend_responses' => 'posts#friend_responses'
      get 'public_responses' => 'posts#public_responses'
      put 'disable' => 'posts#disable'
      get '' => 'posts#show'
    end

    scope 'likes' do
      post '' => 'likes#create'
      delete '' => 'likes#destroy'
    end

    scope 'invite_codes' do
      post 'check' => 'invite_codes#check'
    end
  end

  # Resque admin
  mount Resque::Server, :at => "resque"

  # Soulmate api
  mount Soulmate::Server, :at => "autocomplete"

  # Testing
  get 'testing' => 'testing#test', :as => :test

  # Embedly
  get 'embed' => 'embedly#show', :as => :embedly_fetch

  # Uploads
  #match "/upload" => "uploads#create", :as => :upload_tmp

  # Users
  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks",
                                       :registrations => :registrations,
                                       :confirmations => :confirmations }
  #omniauth passthrough (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
  get '/users/auth/:provider' => 'omniauth_callbacks#passthru'

  scope 'users' do
    get ':id/following/users' => 'users#show', :as => :user_following_topics
    get ':id/following/topics' => 'users#show', :as => :user_following_users
    get ':id/followers' => 'users#show', :as => :user_followers
    get ':id/likes' => 'users#show', :as => :user_likes
    get ':id' => 'users#show', :as => :user
  end
  resources :posts, :only => [:show]

  # Pages
  scope 'pages' do
    get 'about' => 'pages#about', :as => :about_path
    get 'contact' => 'pages#contact', :as => :contact_path
    get 'privacy' => 'pages#privacy', :as => :privacy_path
    get 'terms' => 'pages#terms', :as => :terms_path
    get 'help' => 'pages#help', :as => :help_path
  end

  # Invites
  resources :invite_codes, :only => [:create, :new]
  post '/invite_codes/check' => 'invite_codes#check', :as => :check_invite_code

  #Topics (catch all)
  get ':id' => 'topics#show', :as => :topic

  root :to => 'users#feed'

  #scope 'users' do
  #  get 'settings' => 'users#settings', :as => :user_settings
  #  put 'picture' => "users#picture_update", :as => :user_picture_update
  #  put 'update_settings' => 'users#update_settings', :as => :update_settings
  #  get ':id/following/users' => 'users#following_users', :as => :user_following_users
  #  get ':id/following/topics' => 'users#following_topics', :as => :user_following_topics
  #  get ':id/followers' => 'users#followers', :as => :user_followers
  #  get ':id' => 'users#feed', :as => :user_feed
  #  get ':id/hover' => 'users#hover' , :as => :user_hover
  #  get ':id/picture' => 'users#default_picture', :as => :user_default_picture
  #end

  #scope 'sentiment' do
  #  post ':sentiment' => 'sentiments#create', :as => :sentiment_create
  #end

  # Moderate
  #scope 'moderate' do
  #  get 'connections' => 'topic_con_sugs#new', :as => :moderate_connections
  #end

  # Topics
  #resources :topics, :except => [:edit, :show, :update, :index, :destroy]
  #get '/topics/by_health' => 'topics#by_health', :as => :topics_by_health
  #get 'topics/mention_suggestion' => 'topics#mention_suggestion', :as => :mention_suggestion
  #get '/:id/edit' => 'topics#edit', :as => :edit_topic
  #get '/:id/connected' => 'topics#connected', :as => :connected_topics
  #get '/:id/hover' => 'topics#hover' , :as => :topic_hover
  #put '/:id/picture' => 'topics#picture_update', :as => :topic_picture_update
  #get '/:id/picture' => 'topics#default_picture', :as => :topic_default_picture
  #get '/:id/followers' => 'topics#followers', :as => :topic_followers
  #post '/:id/merge' => 'topics#merge', :as => :merge_topic
  #put '/:id/aliases' => 'topics#update_alias', :as => :update_topic_alias
  #delete '/:id/aliases' => 'topics#destroy_alias', :as => :destroy_topic_alias
  #post '/:id/aliases' => 'topics#add_alias', :as => :add_topic_alias
  #get '/:id/freebase_lookup' => 'topics#freebase_lookup', :as => :freebase_lookup
  #post ':id/freebase_update' => 'topics#freebase_update', :as => :freebase_update
  #put '/:id/lock_slug' => 'topics#lock_slug', :as => :lock_topic_slug
  #get '/:id/pull_from' => 'topics#pull_from', :as => :topic_pull_from
  #get '/:id/google_images' => 'topics#google_images', :as => :topic_google_images
  #get '/:id' => 'topics#show', :as => :topic
  #delete '/:id' => 'topics#destroy', :as => :topic
  #put '/:id' => 'topics#update', :as => :update_topic

  # Topic Connection Suggestions
  #resources :topic_con_sugs, :only => [:create]
  #get 'topic_con_sugs/list' => 'topic_con_sugs#list', :as => :list_topic_con_sugs

  # Topic Connections
  #resources :topic_connections, :only => [:create, :new]
  #post 'topic_connections/add' => 'topic_connections#add', :as => :add_connection
  #delete 'topic_connections/remove' => 'topic_connections#remove', :as => :remove_connection
  #put 'topic_connections/toggle_primary' => 'topic_connections#toggle_primary', :as => :toggle_primary

  # Pages
  #get '/pages/everything' => 'pages#everything', :as => :everything
  #get '/pages/admin' => 'pages#admin', :as => :admin_dashboard
  #get '/pages/splash' => 'pages#splash', :as => :splash
  #root :to => 'users#feed'

















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
