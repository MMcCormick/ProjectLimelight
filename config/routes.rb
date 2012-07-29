ProjectLimelight::Application.routes.draw do

  # redirect to example.com if user goes to www.example.com
  match '(*any)' => redirect { |p, req| req.url.sub('www.', '') }, :constraints => { :host => /^www\./ }

  get 'switch_user', :controller => 'switch_user', :action => 'set_current_user'

  # API
  scope 'api' do
    scope 'users' do
      scope 'follows' do
        post '' => 'follows#create', :type => 'User'
        delete '' => 'follows#destroy', :type => 'User'
      end
      scope 'stubs' do
        post '' => 'users#create_stub'
      end

      post 'invite_by_email' => 'users#invite_by_email'
      get 'index' => 'users#index'
      get 'notifications' => 'users#notifications'
      get 'following_users' => 'users#following_users'
      get 'following_topics' => 'users#following_topics'
      get 'followers' => 'users#followers'
      get 'influence_increases' => 'users#user_influence_increases'
      get 'influencer_topics' => 'users#influencer_topics'
      get 'almost_influencer_topics' => 'users#almost_influencer_topics'
      get ':id/topic_activity' => 'users#topic_activity'
      get ':id/topics/:topic_id/children' => 'users#topic_children'
      get ':id/topics/:topic_id/parents' => 'users#topic_parents'
      get ':id/topics' => 'users#topics'
      put ':id/networks' => 'users#update_network'
      post '' => 'users#create'
      put '' => 'users#update'
      get ':id' => 'users#show'
      get '' => 'users#show'
    end

    scope 'topics' do
      scope 'follows' do
        post '' => 'follows#create', :type => 'Topic'
        delete '' => 'follows#destroy', :type => 'Topic'
      end

      scope 'connections' do
        post '' => 'topic_connections#add'
        get '' => 'topic_connections#index'
        delete '' => 'topic_connections#remove'
      end

      scope 'aliases' do
        post '' => 'topics#add_alias'
        put '' => 'topics#update_alias'
        delete '' => 'topics#destroy_alias'
      end

      post 'update_image' => 'topics#update_image'
      get 'followers' => 'topics#followers'
      get 'suggestions' => 'topics#suggestions'
      get 'index' => 'topics#index'
      get 'categories' => 'topics#categories'
      get 'top_by_category' => 'topics#top_by_category'
      get 'for_connection' => 'topics#for_connection'

      scope ':id' do
        put 'freebase' => 'topics#update_freebase'
        delete 'freebase' => 'topics#delete_freebase'
        put 'categories' => 'topics#add_category'
        get 'children' => 'topics#children'
        get 'parents' => 'topics#parents'
        get '' => 'topics#show'
      end

      delete '' => 'topics#destroy'
      post '' => 'topics#create', :as => :topics
      put '' => 'topics#update'
      get '' => 'topics#index'
    end

    scope 'posts' do
      post '' => 'posts#create'
      get 'stream' => 'posts#stream'
      get 'user_feed' => 'posts#user_feed'
      get 'activity_feed' => 'posts#activity_feed'
      get 'topic_feed' => 'posts#topic_feed'
      get 'responses' => 'posts#responses'
      put 'disable' => 'posts#disable'
      delete 'mentions' => 'posts#delete_mention'
      post 'mentions' => 'posts#create_mention'
      post ':id/shares' => 'posts#publish_share'
      delete ':id/shares' => 'posts#discard_share'
      post ':id/publish' => 'posts#publish'
      delete ':id' => 'posts#destroy'
      get ':id' => 'posts#show'
      get '' => 'posts#index'
    end

    scope 'comments' do
      get '' => 'comments#index'
      post '' => 'comments#create'
      delete '' => 'comments#destroy'
    end

    scope 'invite_codes' do
      post 'check' => 'invite_codes#check'
    end

    scope 'beta_signups' do
      post '' => 'beta_signups#create'
    end

    get 'influence_increases' => 'users#influence_increases'
  end

  # Resque admin
  resque_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.role?('admin')
  end
  constraints resque_constraint do
    mount Resque::Server, :at => "admin/resque"
  end

  # Soulmate api
  mount Soulmate::Server, :at => "autocomplete"

  # Testing
  get 'testing' => 'testing#test', :as => :test

  # Embedly
  get 'embed' => 'embedly#show', :as => :embedly_fetch

  # Uploads
  #match "/upload" => "uploads#create", :as => :upload_tmp

  # Users
  devise_for :users, :skip => [:sessions], :controllers => { :omniauth_callbacks => "omniauth_callbacks",
                                           :registrations => :registrations,
                                           :confirmations => :confirmations,
                                           :sessions => :sessions }
  devise_scope :user do
    get '' => 'users#feed', :as => :new_user_session
    post 'sign_in' => 'sessions#create', :as => :user_session
    get 'sign_out' => 'sessions#destroy', :as => :destroy_user_session
  end
  #omniauth passthrough (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
  get '/users/auth/:provider' => 'omniauth_callbacks#passthru'

  scope 'users' do
    get ':slug/users' => 'users#show', :as => :user_topics
    get ':slug/topics' => 'users#show', :as => :user_users
    get ':slug/feed' => 'users#show', :as => :user_feed
    get ':slug/:topic_id' => 'users#show', :as => :user_topic_activity
    get ':slug' => 'users#show', :as => :user, :show_og => true
  end
  get 'invited' => 'invite_codes#check', :as => :invited
  get 'settings' => 'users#settings', :as => :user_settings
  get 'activity/:topic_id' => 'users#show'
  get 'activity' => 'users#show'
  get 'users' => 'users#show'
  get 'topics' => 'users#show'
  get 'posts/new' => 'posts#new', :as => :new_post
  get 'posts/:id' => 'posts#show', :as => :post

  # Pages
  scope 'pages' do
    get 'about' => 'pages#about', :as => :about
    get 'contact' => 'pages#contact', :as => :contact
    get 'privacy' => 'pages#privacy', :as => :privacy
    get 'terms' => 'pages#terms', :as => :terms
    get 'help' => 'pages#help', :as => :help
    get 'bookmarklet' => 'pages#bookmarklet', :as => :bookmarklet
    scope 'admin' do
      get '' => 'pages#admin', :as => :admin, :require_admin => true
      get 'users/index' => 'users#show', :as => :user_index, :require_admin => true
      get 'users/new_stub' => 'users#show', :as => :new_stub_user, :require_admin => true
      get 'topics/duplicates' => 'topics#duplicates', :as => :admin_topic_duplicates
      get 'topics/for_connection' => 'users#show', :as => :topics_for_connection, :require_admin => true
      get 'posts/stream' => 'users#show', :as => :admin_post_stream, :require_admin => true
    end
  end

  # Invites
  resources :invite_codes, :only => [:create, :new]
  post '/invite_codes/check' => 'invite_codes#check', :as => :check_invite_code
  get '/contacts/:provider/callback' => 'users#show_contacts', :as => :show_contacts
  get '/contacts/failure' => 'users#contacts_failure', :as => :contacts_failure

  # Crawler
  resources :crawler_sources

  # Topics
  get 'topics/new' => 'topics#new', :as => :new_topic
  get ':slug/users' => 'topics#show', :as => :topic_users
  get ':slug' => 'topics#show', :as => :topic #(catch all)

  root :to => 'users#feed'

















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
