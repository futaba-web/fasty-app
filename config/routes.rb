# config/routes.rb
Rails.application.routes.draw do
  # ===================== Devise =====================
  # users 名前空間のコントローラを使用
  devise_for :users, controllers: {
    sessions:           "users/sessions",
    registrations:      "users/registrations",
    passwords:          "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks" # Google などのコールバック
  }

  # 迷いアクセス対策：/users は存在しないためログインへ誘導
  get "/users", to: redirect("/users/sign_in")

  # ===================== 開発用 =====================
  if Rails.env.development?
    # 開発時のメール受信箱（/letter_opener）
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # ===================== 単数系：同意フロー =====================
  resource :health_notice,
           only: %i[show create],
           controller: "health_notice",
           path: "health-notice" do
    get :long
  end

  # ===================== マイページ =====================
  # /mypage -> MypagesController#show
  resource :mypage, only: :show

  # ログイン状態でトップ切り替え
  authenticated :user do
    root to: "mypages#show", as: :authenticated_root
  end
  unauthenticated do
    root to: "pages#home", as: :unauthenticated_root
  end

  # ランディング直アクセス（任意）
  get "pages/home", to: "pages#home", as: :pages_home

  # ===================== ファスティング記録 =====================
  resources :fasting_records, only: %i[index show new create edit update destroy] do
    post :start,  on: :collection
    post :finish, on: :member

    member do
      get   :edit_comment
      patch :update_comment
    end
  end

  # ===================== 瞑想リンク（MVP） =====================
  resources :meditations, only: :index

  # ===================== ヘルスチェック =====================
  get "up", to: "rails/health#show", as: :rails_health_check

  # ===================== PWA関連 =====================
  # NOTE:
  #  - 現在は public/service-worker.js を直接配信する構成。
  #  - 下記の rails/pwa ルートを有効にすると SW が差し替わるためコメントアウト。
  #
  # get "service-worker.js", to: "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest.json",     to: "rails/pwa#manifest",       as: :pwa_manifest
end
