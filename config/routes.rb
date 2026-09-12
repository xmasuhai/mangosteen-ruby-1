Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      # /api/v1
      resources :validation_codes, only: [ :create ]
      resources :session, only: [ :create, :destroy ]
      resources :me, only: [ :show ]
      resources :items, exclude: [ :put ]
      resources :tags, exclude: [ :put ]
    end
  end
end
