Rails.application.routes.draw do
  mount BrowseEverything::Engine => '/browse'
  root to: 'homepage#index'

  delete '/content_blocks/:id',
    as: 'destroy_content_block',
    to: 'galter_content_blocks#destroy'
  patch '/content_blocks/:id/refeature_researcher',
    as: 'refeature_researcher',
    to: 'galter_content_blocks#refeature_researcher'
  get 'help' => 'pages#show', id: 'help_page'
  get 'terms' => 'pages#show', id: 'terms_page'
  get 'agreement' => 'pages#show', id: 'agreement_page'
  get 'news' => 'pages#show', id: 'news_page'
  get '/authorities/generic_files/mesh' => 'custom_authorities#query_mesh'
  get '/authorities/generic_files/creator' => 'custom_authorities#query_users'
  get '/authorities/generic_files/contributor' => 'custom_authorities#query_users'
  get '/authorities/generic_files/verify_user' => 'custom_authorities#verify_user'
  get '/authorities/generic_files/subject_name' => 'custom_authorities#lcsh_names'
  get '/users/new' => 'users#new', as: 'new_user'
  post '/users' => 'users#create', as: 'create_user'
  mount Qa::Engine => '/qa'
  mount Riiif::Engine => '/image-service'

  blacklight_for :catalog

  devise_for :users, :controllers => {
    :omniauth_callbacks => "users/omniauth_callbacks",
    :sessions => "users/sessions"
  }

  mount Hydra::RoleManagement::Engine => '/'

  Hydra::BatchEdit.add_routes(self)

  get '/iiif-api/collection/:id/manifest', to: 'iiif_apis#manifest', as: 'iiif_apis_manifest'
  get '/iiif-api/collection/:id/sequence/:name', to: 'iiif_apis#sequence', as: 'iiif_apis_sequence'
  get '/iiif-api/generic_file/:id/canvas/:name', to: 'iiif_apis#canvas', as: 'iiif_apis_canvas'
  get '/iiif-api/generic_file/:id/annotation/:name', to: 'iiif_apis#annotation', as: 'iiif_apis_annotation'
  get '/iiif-api/generic_file/:id/list/:name', to: 'iiif_apis#list', as: 'iiif_apis_list'

  Sufia::Engine.routes.draw do
    resources :pages, :path => :generic_files
  end

  Hydra::Collections::Engine.routes.draw do
    post '/collections/:id/follow', to: 'collections#follow', as: 'follow_collection'
    delete '/collections/:id/unfollow', to: 'collections#unfollow', as: 'unfollow_collection'
  end

  # This must be the very last route in the file because it has a catch-all route for 404 errors.
  # This behavior seems to show up only in production mode.
  mount Sufia::Engine => '/'
end
