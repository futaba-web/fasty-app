# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  # ログイン状態でトップを切り替え
  authenticated :user do
    root to: "fasting_records#index", as: :authenticated_root
  end

  unauthenticated do
    root to: "pages#home", as: :unauthenticated_root
  end

  # ランディングを直接見たいとき用（任意）
  get "pages/home", to: "pages#home"

  resources :fasting_records, only: %i[index show new create edit update destroy] do
    post :start,  on: :collection
    post :finish, on: :member
  end

  # 旧: welcome は未使用なら削除
  # get "welcome", to: "home#index", as: :welcome

  # ヘルスチェック / PWA
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
