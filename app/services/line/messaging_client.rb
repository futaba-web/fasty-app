# frozen_string_literal: true

module Line
  class MessagingClient
    def initialize
      cfg = Rails.configuration.x.line_messaging

      @client = ::Line::Bot::Client.new do |config|
        config.channel_secret = cfg[:channel_secret]
        config.channel_token  = cfg[:access_token]
      end
    end

    # シンプルなテキスト送信だけまず用意
    # to: LINE の userId（"U" で始まる文字列）
    def push_text(to:, text:)
      message = { type: "text", text: text }
      @client.push_message(to, message)
    end
  end
end
