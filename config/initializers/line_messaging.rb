# config/initializers/line_messaging.rb
require "net/http"
require "uri"
require "json"

module LineMessaging
  module_function

  LINE_PUSH_ENDPOINT = "https://api.line.me/v2/bot/message/push"

  # 環境変数が揃っているかチェック
  def channel_access_token
    token = ENV["LINE_MESSAGING_CHANNEL_ACCESS_TOKEN"]
    if token.blank?
      Rails.logger.error "[LineMessaging] LINE_MESSAGING_CHANNEL_ACCESS_TOKEN が設定されていません"
    end
    token
  end

  # シンプルなテキスト push 用ヘルパー
  #
  #   user: line_user_id / line_notify_enabled を持つ User
  #   text: 送りたいメッセージ本文
  #
  def push_text(user, text)
    return if user.blank?
    return if user.line_user_id.blank?
    return if text.blank?
    return if channel_access_token.blank?

    uri = URI.parse(LINE_PUSH_ENDPOINT)

    body_hash = {
      to: user.line_user_id,
      messages: [
        {
          type: "text",
          text:
        }
      ]
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type"  => "application/json",
      "Authorization" => "Bearer #{channel_access_token}"
    })
    request.body = body_hash.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error(
        "[LineMessaging] push_text failed " \
        "status=#{response.code} body=#{response.body}"
      )
    end

    response
  rescue StandardError => e
    Rails.logger.error "[LineMessaging] push_text exception: #{e.class} #{e.message}"
    nil
  end
end
