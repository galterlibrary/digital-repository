require "resque_web"
Rails.application.routes.draw do
  resque_web_constraint = lambda do |request|
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
  end
  constraints resque_web_constraint do
    mount ResqueWeb::Engine => "/resque_web"
  end

  get '/authorities/generic_files/subject' => 'custom_authorities#query_mesh'
  mount Qa::Engine => '/qa'
  mount Riiif::Engine => '/image-service'

  blacklight_for :catalog
  devise_for :users
  Hydra::BatchEdit.add_routes(self)
  # This must be the very last route in the file because it has a catch-all route for 404 errors.
  # This behavior seems to show up only in production mode.
  mount Sufia::Engine => '/'
  root to: 'homepage#index'

  get '/iiif-api/collection/:id/manifest', to: 'iiif_apis#manifest', as: 'iiif_apis_manifest'
  get '/iiif-api/collection/:id/sequence/:name', to: 'iiif_apis#sequence', as: 'iiif_apis_sequence'
  get '/iiif-api/generic_file/:id/canvas/:name', to: 'iiif_apis#canvas', as: 'iiif_apis_canvas'
  get '/iiif-api/generic_file/:id/annotation/:name', to: 'iiif_apis#annotation', as: 'iiif_apis_annotation'
  get '/iiif-api/generic_file/:id/list/:name', to: 'iiif_apis#list', as: 'iiif_apis_list'

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
