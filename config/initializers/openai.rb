# config/initializers/openai.rb

if ENV["OPENAI_API_KEY"].present?
  OpenAIClient = OpenAI::Client.new(
    access_token: ENV["OPENAI_API_KEY"]
  )
else
  Rails.logger.warn("[OpenAI] OPENAI_API_KEY is not set. AI features are disabled.")
end
