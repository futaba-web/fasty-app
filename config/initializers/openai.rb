# config/initializers/openai.rb

class NullOpenAIClient
  def chat(*, **)
    Rails.logger.warn("[OpenAI] Attempted to call OpenAI without OPENAI_API_KEY. Skipping request.")
    nil
  end

  def enabled?
    false
  end
end

OpenAIClient = if ENV["OPENAI_API_KEY"].present?
                 OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
               else
                 Rails.logger.warn("[OpenAI] OPENAI_API_KEY is not set. AI features are disabled.")
                 NullOpenAIClient.new
               end
