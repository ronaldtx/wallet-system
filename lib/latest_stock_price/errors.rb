module LatestStockPrice
  # Base error
  class Error < StandardError; end

  # Configuration not complete
  class ConfigurationError < Error; end

  # 401 / 403 from API
  class AuthenticationError < Error; end

  # 429 — rate limit
  class RateLimitError < Error; end

  # 4xx others (400, 404, dll)
  class ClientError < Error; end

  # 5xx from server
  class ServerError < Error; end

  # Timeout / network error
  class ConnectionError < Error; end

  # Response not JSON valid
  class ParseError < Error; end
end