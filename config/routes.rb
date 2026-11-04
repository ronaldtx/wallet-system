Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "/me", to: "sessions#me"

  # Defines the root path route ("/")
  # root "posts#index"

  # === Auth ===
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get    "/me",     to: "sessions#me"

  # === Wallets ===
  resources :wallets, only: [:show] do
    member do
      get  :transactions          # GET /wallets/:id/transactions
      post :deposit               # POST /wallets/:id/deposit
      post :withdraw              # POST /wallets/:id/withdraw
    end
  end

  # === Transfers ===
  post "/transfers", to: "transactions#create"
end
