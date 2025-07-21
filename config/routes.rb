Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      post "check_api_health", to: "health_monitor#check"
      get "uptime_history", to: "health_monitor#history"
      get "uptime_summary", to: "health_monitor#uptime_summary"
      get "uptime_dashboard", to: "health_monitor#dashboard"
    end
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
