# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
  sessions:      'users/sessions',
  registrations: 'users/registrations',
  passwords:     'users/passwords'
}

  # --- 健康と安全（同意フロー / 単数リソース） ---
  # 画面:  GET  /health-notice        -> HealthNoticeController#show
  # 同意:  POST /health-notice        -> HealthNoticeController#create
  # 長時間: GET  /health-notice/long  -> HealthNoticeController#long
  resource :health_notice,
           only: [ :show, :create ],
           controller: "health_notice",
           path: "health-notice" do
    get :long
  end

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
    post :start,  on: :collection   # POST /fasting_records/start
    post :finish, on: :member       # POST /fasting_records/:id/finish

    # ▼ コメント専用編集・更新
    member do
      get   :edit_comment          # GET   /fasting_records/:id/edit_comment
      patch :update_comment        # PATCH /fasting_records/:id/update_comment
    end
  end

  # --- 瞑想リンク（MVPは外部リンク一覧のみ） ---
  resources :meditations, only: :index

  # --- ヘルスチェック / PWA ---
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker.js" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest.json"     => "rails/pwa#manifest",       as: :pwa_manifest
end
