module LatestStockPrice
  class Configuration
    attr_accessor :api_key, :base_url, :host, :open_timeout, :read_timeout

    def initialize
      @api_key       = ENV["RAPIDAPI_KEY"]
      @base_url      = ENV.fetch("LATEST_STOCK_PRICE_URL", "https://latest-stock-price.p.rapidapi.com")
      @host          = ENV.fetch("LATEST_STOCK_PRICE_HOST", "latest-stock-price.p.rapidapi.com")
      @open_timeout  = 5
      @read_timeout  = 10
    end

    def validate!
      if api_key.nil? || api_key.strip.empty?
        raise ConfigurationError, "RAPIDAPI_KEY belum di-set (ENV atau LatestStockPrice.configure)"
      end
    end
  end
end