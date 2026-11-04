require "net/http"
require "json"
require "uri"

module LatestStockPrice
  class Client
    attr_reader :config

    def initialize(config = LatestStockPrice.configuration)
      @config = config
    end

    # GET /price?symbol=AAPL
    def price(symbol)
      raise ArgumentError, "symbol mandatory" if symbol.nil? || symbol.to_s.strip.empty?

      response = get("/price", { symbol: symbol.to_s.upcase })
      parse_json(response)
    end

    # GET /prices?symbols=AAPL,GOOG
    def prices(symbols)
      list = Array(symbols).map { |s| s.to_s.strip.upcase }.reject(&:empty?)
      raise ArgumentError, "symbols mandatory" if list.empty?

      response = get("/prices", { symbols: list.join(",") })
      parse_json(response)
    end

    # GET /price_all
    def price_all
      response = get("/price_all")
      parse_json(response)
    end

    private

    def get(path, params = {})
      config.validate!

      uri = URI.join(config.base_url, path)
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = config.open_timeout
      http.read_timeout = config.read_timeout

      request = Net::HTTP::Get.new(uri)
      request["X-RapidAPI-Key"]  = config.api_key
      request["X-RapidAPI-Host"] = config.host
      request["Accept"]          = "application/json"

      response = http.request(request)

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ConnectionError, "Timeout: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED => e
      raise ConnectionError, "connection failed: #{e.message}"
    end

    def handle_response(response)
      code = response.code.to_i

      case code
      when 200..299
        response.body
      when 401, 403
        raise AuthenticationError, "Auth failed (#{code}): #{response.body}"
      when 429
        raise RateLimitError, "Rate limit (#{code}): #{response.body}"
      when 400..499
        raise ClientError, "Client error (#{code}): #{response.body}"
      when 500..599
        raise ServerError, "Server error (#{code}): #{response.body}"
      else
        raise Error, "Unexpected status #{code}: #{response.body}"
      end
    end

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise ParseError, "Response not JSON valid: #{e.message}"
    end
  end
end