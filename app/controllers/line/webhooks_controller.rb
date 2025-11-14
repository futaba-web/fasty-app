# app/controllers/line/webhooks_controller.rb
module Line
  class WebhooksController < ApplicationController
    # 外部サービス（LINE）からの POST を受け取るので CSRF チェックは外す
    skip_before_action :verify_authenticity_token

    def callback
      # とりあえず生のボディをログに出すだけ（動作確認用）
      raw_body = request.body.read
      Rails.logger.info "[LINE Webhook] raw_body=#{raw_body}"

      # 常に 200 を返す（LINE 側の「確認する」が成功しやすいように）
      head :ok
    end
  end
end
