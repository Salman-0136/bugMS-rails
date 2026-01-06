Rails.application.routes.draw do
  # Devise routes
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    sign_up: "signup"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  root "pages#home"
  get "about", to: "pages#about"
  get "contact", to: "pages#contact"

  get "admin/dashboard", to: "users#admin_dashboard", as: :admin_dashboard

  post "users/:id/send_reset", to: "users#send_reset", as: "send_reset_user"

  # ---------- BUGS ----------

  get    "bugs/import_page",             to: "bugs#import_page",            as: :import_bugs_page
  post   "bugs/import",                  to: "bugs#import",                 as: :import_bugs
  get    "/bugs/import_errors",          to: "bugs#download_import_errors", as: :download_import_errors_bugs
  get    "/bugs/export",                 to: "bugs#export",                 as: :export_bugs
  get    "/bugs/export/download",        to: "bugs#export_download",        as: :download_export_bugs

  get    "bugs",                         to: "bugs#index",                  as: :bugs
  get    "bugs/new",                     to: "bugs#new",                    as: :new_bug
  post   "bugs",                         to: "bugs#create"
  get    "bugs/:id",                     to: "bugs#show",                   as: :bug
  get    "bugs/:id/edit",                to: "bugs#edit",                   as: :edit_bug
  patch  "bugs/:id",                     to: "bugs#update"
  delete "bugs/:id",                     to: "bugs#destroy"
  get    "my_bugs",                      to: "bugs#my_bugs",                as: :my_bugs
  get    "project_bugs/:project_id",     to: "bugs#project_bugs",           as: :project_bugs

  # ---------- USERS ----------
  get    "users",          to: "users#index", as: :users
  get    "users/:id",      to: "users#show",  as: :user
  delete "users/:id",      to: "users#destroy"

  # ---------- COMMENTS ----------
  get    "comments",        to: "comments#index"
  get    "comments/new",    to: "comments#new", as: :new_comment
  post   "comments",        to: "comments#create"
  get    "comments/:id",    to: "comments#show", as: :comment
  delete "comments/:id",    to: "comments#destroy"

  # ---------- PROJECTS ----------

  get    "projects/import_page",      to: "projects#import_page",            as: :import_projects_page
  post   "projects/import",           to: "projects#import",                 as: :import_projects
  get    "/projects/import_errors",   to: "projects#download_import_errors", as: :download_import_errors_projects
  get    "/projects/export",          to: "projects#export",                 as: :export_projects
  get    "/projects/export/download", to: "projects#export_download",        as: :download_export_projects

  get    "projects",                 to: "projects#index",                  as: :projects
  get    "projects/new",             to: "projects#new",                    as: :new_project
  post   "projects",                 to: "projects#create"
  get    "projects/:id",             to: "projects#show",                   as: :project
  get    "projects/:id/edit",        to: "projects#edit",                   as: :edit_project
  patch  "projects/:id",             to: "projects#update"
  delete "projects/:id",             to: "projects#destroy"
  get    "my_projects",              to: "projects#my_projects",            as: :my_projects

  # ---------- SEARCH ----------
  get "search", to: "search#index", as: :search
end
