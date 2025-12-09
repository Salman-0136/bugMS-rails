Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  root "pages#home"
  get "about", to: "pages#about", as: :about
  get "contact", to: "pages#contact", as: :contact

  get "bugs", to: "bugs#index", as: :bugs
  get "bugs/new", to: "bugs#new", as: :new_bug
  post "bugs", to: "bugs#create"
  get "bugs/:id", to: "bugs#show", as: :bug
  get "bugs/:id/edit", to: "bugs#edit", as: :edit_bug
  patch "bugs/:id", to: "bugs#update"
  delete "bugs/:id", to: "bugs#destroy"
  get "my_bugs", to: "bugs#my_bugs", as: :my_bugs

  get "users", to: "users#index", as: :users
  get "users/:id", to: "users#show", as: :user
  get "signup", to: "users#new", as: :signup
  post "users", to: "users#create"
  get "users/:id/edit", to: "users#edit", as: :edit_user
  patch "users/:id", to: "users#update"
  delete "users/:id", to: "users#destroy"

  get "comments", to: "comments#index", as: :comments
  get "comments/:id", to: "comments#show", as: :comment
  get "comments/new", to: "comments#new", as: :new_comment
  post "comments", to: "comments#create"
  delete "comments/:id", to: "comments#destroy"

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "projects", to: "projects#index", as: :projects
  get "projects/new", to: "projects#new", as: :new_project
  post "projects", to: "projects#create"
  get "projects/:id", to: "projects#show", as: :project
  get "projects/:id/edit", to: "projects#edit", as: :edit_project
  patch "projects/:id", to: "projects#update"
  delete "projects/:id", to: "projects#destroy"
  get "my_projects", to: "projects#my_projects", as: :my_projects

  get "/search", to: "search#index", as: "search"
end
