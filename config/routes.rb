# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  # --- マイページ（ログイン後の着地点） ---
  resource :mypage, only: :show  # /mypage -> MypagesController#show

  # ログイン状態でトップ切り替え
  authenticated :user do
    root to: "mypages#show", as: :authenticated_root
  end
  unauthenticated do
    root to: "pages#home", as: :unauthenticated_root
  end

  # ランディング直アクセス（任意）
  get "pages/home", to: "pages#home"

  # --- ファスティング記録 ---
  resources :fasting_records, only: %i[index show new create edit update destroy] do
    # 開始はコレクション、終了はレコード単位
    post :start,  on: :collection   # POST /fasting_records/start
    post :finish, on: :member       # POST /fasting_records/:id/finish
  end

  # --- 瞑想リンク（MVPは外部リンク一覧のみ） ---
  resources :meditations, only: :index

  # --- ヘルスチェック / PWA ---
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker.js" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest.json"     => "rails/pwa#manifest",       as: :pwa_manifest
end
