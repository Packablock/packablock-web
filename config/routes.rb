Rails.application.routes.draw do
  devise_for :admins

  authenticate :admin do
    root to: "dashboard#index"

    get "dashboard" => "dashboard#index", as: :dashboard

    resources :projects do
      member do
        post :link_repository
        delete :unlink_repository
      end
    end

    resources :repositories, only: [:show] do
      member do
        post :toggle_premium
        post :revoke
        get :tree
      end
      collection do
        post :purge_stale
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
