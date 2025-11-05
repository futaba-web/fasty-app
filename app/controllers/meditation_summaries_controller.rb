# app/controllers/meditation_summaries_controller.rb
class MeditationSummariesController < ApplicationController
  before_action :authenticate_user!

  def show
    # ひとまずプレースホルダー
    # 週・月の統計などは後続Issueで実装
  end
end
