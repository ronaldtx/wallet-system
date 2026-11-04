require "test_helper"
require "webmock/minitest"

class LatestStockPriceTest < ActiveSupport::TestCase
  def setup
    ENV.delete("RAPIDAPI_KEY")
    LatestStockPrice.reset_configuration!
    LatestStockPrice.configure { |c| c.api_key = "test-key" }
    WebMock.disable_net_connect!
  end

  def teardown
    LatestStockPrice.reset_configuration!
    WebMock.reset!
  end

  test "price returns parsed JSON" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price")
      .with(
        query: { symbol: "AAPL" },
        headers: {
          "X-RapidAPI-Key"  => "test-key",
          "X-RapidAPI-Host" => "latest-stock-price.p.rapidapi.com"
        }
      )
      .to_return(
        status: 200,
        body: { symbol: "AAPL", price: 150.5 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = LatestStockPrice.price("aapl")
    assert_equal "AAPL", result["symbol"]
    assert_equal 150.5, result["price"]
  end

  test "prices joins symbols with comma and upcases" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/prices")
      .with(query: { symbols: "AAPL,GOOG" })
      .to_return(
        status: 200,
        body: [{ symbol: "AAPL" }, { symbol: "GOOG" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = LatestStockPrice.prices(["aapl", "goog"])
    assert_equal 2, result.size
  end

  test "price_all hits /price_all" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price_all")
      .to_return(
        status: 200,
        body: [{ symbol: "AAPL" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = LatestStockPrice.price_all
    assert_equal 1, result.size
  end

  test "raises ConfigurationError when api_key missing" do
    LatestStockPrice.reset_configuration!

    assert_raises(LatestStockPrice::ConfigurationError) do
      LatestStockPrice.price("AAPL")
    end
  end

  test "raises AuthenticationError on 401" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price")
      .with(query: { symbol: "AAPL" })
      .to_return(status: 401, body: "unauthorized")

    assert_raises(LatestStockPrice::AuthenticationError) do
      LatestStockPrice.price("AAPL")
    end
  end

  test "raises RateLimitError on 429" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price")
      .with(query: { symbol: "AAPL" })
      .to_return(status: 429, body: "too many requests")

    assert_raises(LatestStockPrice::RateLimitError) do
      LatestStockPrice.price("AAPL")
    end
  end

  test "raises ServerError on 500" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price")
      .with(query: { symbol: "AAPL" })
      .to_return(status: 500, body: "server error")

    assert_raises(LatestStockPrice::ServerError) do
      LatestStockPrice.price("AAPL")
    end
  end

  test "raises ParseError on invalid JSON" do
    stub_request(:get, "https://latest-stock-price.p.rapidapi.com/price")
      .with(query: { symbol: "AAPL" })
      .to_return(
        status: 200,
        body: "bukan json",
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(LatestStockPrice::ParseError) do
      LatestStockPrice.price("AAPL")
    end
  end
end