ActionController::Routing::Routes.draw do |map|
  map.resources :users

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  # authlogic authentication
  map.resource :user_session
  map.default "/", :controller => "user_sessions", :action => "new"
  
  # TODO add static_actions gem with a home page
  map.root :controller => "user_sessions", :action => "new"
  
  # user accounts
  map.resource :account, :controller => "users"
  map.resources :users
  
  # RESTful rewrites from baseapp
  map.signup   '/signup',   :controller => 'users',    :action => 'new'
  map.login    '/login',    :controller => 'user_sessions', :action => 'new'
  map.logout   '/logout',   :controller => 'user_sessions', :action => 'destroy', :conditions => {:method => :delete}
  
  # TODO
  # map.register '/register', :controller => 'users',    :action => 'create'
  # map.activate '/activate/:activation_code', :controller => 'users',    :action => 'activate'
  
  # User interactions from baseapp
  # TODO
  # map.user_troubleshooting '/users/troubleshooting', :controller => 'users', :action => 'troubleshooting'
  # map.user_forgot_password '/users/forgot_password', :controller => 'users', :action => 'forgot_password'
  # map.user_reset_password  '/users/reset_password/:password_reset_code', :controller => 'users', :action => 'reset_password'
  # map.user_forgot_login    '/users/forgot_login',    :controller => 'users', :action => 'forgot_login'
  # map.user_clueless        '/users/clueless',        :controller => 'users', :action => 'clueless'
  
  # map.resources :users, :member => { :edit_password => :get,
  #                                   :update_password => :put,
  #                                   :edit_email => :get }
                                     
  # Administrator interface from baseapp
  map.namespace(:admin) do |admin|
   admin.root :controller => 'users', :action => 'index'
   admin.resources :users, :member => { :suspend   => :put,
                                        :unsuspend => :put,
                                        :activate  => :put, 
                                        :purge     => :delete,
                                        :reset_password => :put },
                           :collection => { :pending   => :get,
                                            :active    => :get, 
                                            :suspended => :get, 
                                            :deleted   => :get }
  end
  
  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
