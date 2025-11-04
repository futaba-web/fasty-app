Rails.application.config.session_store :cookie_store,
  key: "_fasty_session",
  secure: Rails.env.production?, # HTTPSのみ
  same_site: :lax               # OAuth/Turboと相性◯
