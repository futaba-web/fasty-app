class MeditationsController < ApplicationController
  before_action :authenticate_user!  # ログイン後に見る想定なら

  def index
    path = Rails.root.join("config/meditations.yml")
    raw  = YAML.safe_load_file(path, aliases: false) rescue []
    @meditations = Array(raw).map { |m|
      { title: m["title"].to_s,
        url: m["url"].to_s,
        duration_min: m["duration_min"].to_i,
        tags: Array(m["tags"]).map(&:to_s) }
    }.sort_by { |m| m[:duration_min] }
  end
end
