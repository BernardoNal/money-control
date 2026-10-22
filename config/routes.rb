Rails.application.routes.draw do
  resources :accounts do
    get "transactions/import", to: "transactions/imports#new", as: :transaction_import
    post "transactions/import", to: "transactions/imports#create", as: :transaction_import_create
    get "transactions/import/:id", to: "transactions/imports#show", as: :transaction_import_preview
    patch "transactions/import/:id", to: "transactions/imports#update", as: :transaction_import_update
    post "transactions/import/:id/confirm", to: "transactions/imports#confirm", as: :transaction_import_confirm
    delete "transactions/import/:id", to: "transactions/imports#cancel", as: :transaction_import_cancel
  end
  resources :categories
  resources :transactions
  namespace :investments do
    resources :assets, except: %i[show destroy] do
      collection { get :search }
    end
    resources :portfolios do
      get "income-import", to: "income_imports#new", as: :income_import
      post "income-import", to: "income_imports#create", as: :income_import_create
      get "income-import/:id", to: "income_imports#show", as: :income_import_preview
    end
    resources :incomes
    get "income-tax-report", to: "income_tax_reports#show", as: :income_tax_report
    resources :transactions
  end

  root to: "transactions#dashboard"
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
