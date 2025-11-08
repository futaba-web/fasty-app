# frozen_string_literal: true
require "uri"

class CanonicalHost
  def initialize(app); @app = app; end

  def call(env)
    req = Rack::Request.new(env)
    primary = ENV["PRIMARY_HOST"]
    return @app.call(env) if primary.to_s.empty? || req.host.casecmp?(primary)

    url = URI::HTTPS.build(
      host: primary,
      path: req.path,
      query: req.query_string.presence
    ).to_s
    [ 301, { "Location" => url, "Content-Type" => "text/html" }, [ "Moved Permanently" ] ]
  end
end
