require_relative "latest_stock_price/version"
require_relative "latest_stock_price/errors"
require_relative "latest_stock_price/configuration"
require_relative "latest_stock_price/client"

module LatestStockPrice
  class << self
    # Global Configuration
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    # Reset config
    def reset_configuration!
      @configuration = Configuration.new
      @client = nil
    end

    # Shortcut: LatestStockPrice.price("AAPL")
    def client
      @client ||= Client.new(configuration)
    end

    def price(symbol)
      client.price(symbol)
    end

    def prices(symbols)
      client.prices(symbols)
    end

    def price_all
      client.price_all
    end
  end
end