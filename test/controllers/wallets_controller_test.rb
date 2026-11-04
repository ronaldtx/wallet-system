require "test_helper"

class WalletsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Transaction.delete_all
    Wallet.delete_all
    User.delete_all

    @user   = User.create!(email: "ctrl1@test.com", password: "secret123")
    @user2  = User.create!(email: "ctrl2@test.com", password: "secret123")
    @wallet  = @user.wallet
    @wallet2 = @user2.wallet
  end

  def login_as(user, password: "secret123")
    post "/login", params: { email: user.email, password: password }, as: :json
    assert_response :ok
  end

  # === AUTH ===
  test "GET /wallets/:id without login returns 401" do
    get "/wallets/#{@wallet.id}"
    assert_response :unauthorized
  end

  # === SHOW ===
  test "GET /wallets/:id returns 200 with balance" do
    WalletService.deposit(wallet: @wallet, amount: 100)
    login_as(@user)

    get "/wallets/#{@wallet.id}"
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal @wallet.id, body["id"]
    assert_equal 100.0, body["balance"]
    assert_equal "User", body["owner_type"]
  end

  test "GET /wallets/:id for missing wallet returns 404" do
    login_as(@user)
    get "/wallets/999999"
    assert_response :not_found
  end

  # === DEPOSIT ===
  test "POST /wallets/:id/deposit returns 201 and increases balance" do
    login_as(@user)

    post "/wallets/#{@wallet.id}/deposit",
         params: { amount: 100 }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 100.0, body["balance"]
    assert_equal "Credit", body["transaction"]["type"]
    assert_equal 100.0, @wallet.reload.balance
  end

  test "POST /wallets/:id/deposit with amount 0 returns 422" do
    login_as(@user)
    post "/wallets/#{@wallet.id}/deposit", params: { amount: 0 }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /wallets/:id/deposit without amount returns 400" do
    login_as(@user)
    post "/wallets/#{@wallet.id}/deposit", params: {}, as: :json
    assert_response :bad_request
  end

  # === WITHDRAW ===
  test "POST /wallets/:id/withdraw returns 201 and decreases balance" do
    WalletService.deposit(wallet: @wallet, amount: 100)
    login_as(@user)

    post "/wallets/#{@wallet.id}/withdraw",
         params: { amount: 30 }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 70.0, body["balance"]
    assert_equal "Debit", body["transaction"]["type"]
  end

  test "POST /wallets/:id/withdraw with insufficient funds returns 422" do
    WalletService.deposit(wallet: @wallet, amount: 50)
    login_as(@user)

    post "/wallets/#{@wallet.id}/withdraw", params: { amount: 999 }, as: :json
    assert_response :unprocessable_entity
    assert_equal 50.0, @wallet.reload.balance
  end

  # === TRANSACTIONS ===
  test "GET /wallets/:id/transactions returns 200 with an array" do
    WalletService.deposit(wallet: @wallet, amount: 100)
    WalletService.withdraw(wallet: @wallet, amount: 30)
    login_as(@user)

    get "/wallets/#{@wallet.id}/transactions"
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 2, body.size
    assert_equal ["Debit", "Credit"], body.map { |t| t["type"] }
  end
end