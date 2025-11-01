# 起動時に一度だけENVの値をマスクしてログ出力
mask = ->(s) { s.present? ? "#{s[0, 4]}...#{s[-4, 4]}" : "(nil)" }

Rails.logger.info(
  "[OAuth Probe] GOOGLE_CLIENT_ID=#{mask.(ENV['GOOGLE_CLIENT_ID'])} " \
  "GOOGLE_CLIENT_SECRET=#{mask.(ENV['GOOGLE_CLIENT_SECRET'])}"
)
