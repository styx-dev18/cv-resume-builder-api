class Rack::Attack
  # Auth and PDF-generation throttles are added alongside those features (M2/M5).
  # Baseline: throttle all requests per IP as a floor against abuse.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end
end
