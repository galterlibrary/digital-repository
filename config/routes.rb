Rails.application.routes.draw do
  root to: 'homepage#index'

  get 'help' => 'pages#show', id: 'help_page'
  get 'terms' => 'pages#show', id: 'terms_page'
  get 'agreement' => 'pages#show', id: 'agreement_page'
  get 'news' => 'pages#show', id: 'news_page'
  get '/authorities/generic_files/mesh' => 'custom_authorities#query_mesh'
  get '/authorities/generic_files/creator' => 'custom_authorities#query_users'
  get '/authorities/generic_files/contributor' => 'custom_authorities#query_users'
  get '/authorities/generic_files/verify_user' => 'custom_authorities#verify_user'
  get '/authorities/generic_files/subject_name' => 'custom_authorities#lcsh_names'
  mount Qa::Engine => '/qa'
  mount Riiif::Engine => '/image-service'

  blacklight_for :catalog
  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'

  Hydra::BatchEdit.add_routes(self)

  get '/iiif-api/collection/:id/manifest', to: 'iiif_apis#manifest', as: 'iiif_apis_manifest'
  get '/iiif-api/collection/:id/sequence/:name', to: 'iiif_apis#sequence', as: 'iiif_apis_sequence'
  get '/iiif-api/generic_file/:id/canvas/:name', to: 'iiif_apis#canvas', as: 'iiif_apis_canvas'
  get '/iiif-api/generic_file/:id/annotation/:name', to: 'iiif_apis#annotation', as: 'iiif_apis_annotation'
  get '/iiif-api/generic_file/:id/list/:name', to: 'iiif_apis#list', as: 'iiif_apis_list'

  # This must be the very last route in the file because it has a catch-all route for 404 errors.
  # This behavior seems to show up only in production mode.
  mount Sufia::Engine => '/'
end
