# config/routes.rb
Rails.application.routes.draw do
  # ===================== Devise =====================
  # users 名前空間のコントローラを使用
  devise_for :users, controllers: {
    sessions:           "users/sessions",
    registrations:      "users/registrations",
    passwords:          "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks" # Google / LINE Login などのコールバック
  }

  # 迷いアクセス対策：/users は存在しないためログインへ誘導
  get "/users", to: redirect("/users/sign_in")

  # ===================== LINE Messaging API Webhook =====================
  # LINE 側の Webhook URL は
  #   https://<ホスト名>/line/webhook
  # を設定する想定（POST）
  post "/line/webhook", to: "line/webhooks#callback"

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

  # ===================== ガイド（使い方） =====================
  # オンボーディング用の静的ページ。未ログインでも閲覧可想定。
  get "/guide", to: "guides#show", as: :guide

  # ===================== ファスティング記録 =====================
  resources :fasting_records, only: %i[index show new create edit update destroy] do
    collection do
      get  :calendar     # 月カレンダー表示 /fasting_records/calendar
      post :start        # 記録開始
    end

    member do
      post  :finish
      get   :edit_comment
      patch :update_comment
    end
  end

  # ===================== 瞑想（MVP + 週次サマリー/ログ） =====================
  resources :meditations, only: :index
  resources :meditation_logs, only: :create          # 「瞑想を始める」押下時に記録
  resource  :meditation_summary, only: :show         # 今週の回数/合計分など

  # ===================== 法務／お問い合わせ =====================
  scope :legal do
    get "terms",   to: "legal#terms"
    get "privacy", to: "legal#privacy"
  end
  resource :contact, only: %i[new create]            # /contact/new, POST /contact

  # ===================== ヘルスチェック =====================
  # 監視・疎通確認用（SSLリダイレクト除外対象）。/up は Rails 標準ヘルス。
  get  "/health", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "ok" ] ] }
  get  "/up",     to: "rails/health#show", as: :rails_health_check

  # ===================== 静的リクエスト対策 =====================
  # RSS/Atom を提供しないため、古いクローラ向けのURLには 410 Gone を返す
  get "/feeds/all.atom.xml", to: proc { [ 410, { "Content-Type" => "text/plain" }, [ "" ] ] }

  # favicon は public/ に配置しているため通常は不要。
  # もし今後 public/favicon.ico を置かない運用にするなら下記のリダイレクトを有効化。
  # get "/favicon.ico", to: redirect("/favicon.png")

  # ===================== PWA関連（現在は public 直配信） =====================
  # get "service-worker.js", to: "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest.json",     to: "rails/pwa#manifest",       as: :pwa_manifest
end
