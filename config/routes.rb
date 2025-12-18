Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  root "pages#home"
  get "about", to: "pages#about"
  get "contact", to: "pages#contact"

  # ---------- BUG IMPORT / EXPORT ----------
  get  "import_bugs/new",      to: "bugs#import_page",    as: :import_bugs_page
  post "import_bugs",          to: "bugs#import",         as: :import_bugs
  get  "import_bugs/results",  to: "bugs#import_results", as: :import_bugs_results
  get  "bugs/import_result_download/:id",
       to: "bugs#import_result_download",
       as: :import_bug_result_download
  get "bugs/export", to: "bugs#export", as: :export_bugs

  # ---------- BUGS ----------
  get    "bugs",          to: "bugs#index",   as: :bugs
  get    "bugs/new",      to: "bugs#new",     as: :new_bug
  post   "bugs",          to: "bugs#create"
  get    "bugs/:id",      to: "bugs#show",    as: :bug
  get    "bugs/:id/edit", to: "bugs#edit",    as: :edit_bug
  patch  "bugs/:id",      to: "bugs#update"
  delete "bugs/:id",      to: "bugs#destroy"
  get    "my_bugs",       to: "bugs#my_bugs", as: :my_bugs
  get    "project_bugs/:project_id", to: "bugs#project_bugs", as: :project_bugs

  # ---------- USERS ----------
  get    "users",          to: "users#index", as: :users
  get    "users/:id",      to: "users#show",  as: :user
  get    "signup",         to: "users#new",   as: :signup
  post   "users",          to: "users#create"
  get    "users/:id/edit", to: "users#edit",  as: :edit_user
  patch  "users/:id",      to: "users#update"
  delete "users/:id",      to: "users#destroy"

  # ---------- COMMENTS ----------
  get    "comments",        to: "comments#index"
  get    "comments/new",    to: "comments#new", as: :new_comment
  post   "comments",        to: "comments#create"
  get    "comments/:id",    to: "comments#show", as: :comment
  delete "comments/:id",    to: "comments#destroy"

  # ---------- AUTH ----------
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # ---------- PROJECT IMPORT / EXPORT ----------
  get  "import_projects/new",     to: "projects#import_page",    as: :import_projects_page
  post "import_projects",         to: "projects#import",         as: :import_projects
  get  "import_projects/results", to: "projects#import_results", as: :import_projects_results
  get  "projects/export",         to: "projects#export",         as: :export_projects

  # ---------- PROJECTS ----------
  get    "projects",          to: "projects#index", as: :projects
  get    "projects/new",      to: "projects#new",   as: :new_project
  post   "projects",          to: "projects#create"
  get    "projects/:id",      to: "projects#show",  as: :project
  get    "projects/:id/edit", to: "projects#edit",  as: :edit_project
  patch  "projects/:id",      to: "projects#update"
  delete "projects/:id",      to: "projects#destroy"
  get    "my_projects",       to: "projects#my_projects", as: :my_projects

  # ---------- SEARCH ----------
  get "search", to: "search#index", as: :search
end
