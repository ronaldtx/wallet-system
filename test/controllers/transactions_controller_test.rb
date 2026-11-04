require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Transaction.delete_all
    Wallet.delete_all
    User.delete_all

    @user1 = User.create!(email: "tx1@test.com", password: "secret123")
    @user2 = User.create!(email: "tx2@test.com", password: "secret123")
    @w1 = @user1.wallet
    @w2 = @user2.wallet
    WalletService.deposit(wallet: @w1, amount: 100)
  end

  def login_as(user)
    post "/login", params: { email: user.email, password: "secret123" }, as: :json
    assert_response :ok
  end

  test "POST /transfers without login returns 401" do
    post "/transfers", params: {
      from_wallet_id: @w1.id, to_wallet_id: @w2.id, amount: 10
    }, as: :json
    assert_response :unauthorized
  end

  test "POST /transfers returns 201 and updates both balances" do
    login_as(@user1)

    post "/transfers", params: {
      from_wallet_id: @w1.id, to_wallet_id: @w2.id, amount: 40
    }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Transfer", body["transaction"]["type"]
    assert_equal 40.0, body["transaction"]["amount"]
    assert_equal 60.0, body["from_wallet"]["balance"]
    assert_equal 40.0, body["to_wallet"]["balance"]
  end

  test "POST /transfers with insufficient funds returns 422 and rolls back" do
    login_as(@user1)
    before = Transaction.count

    post "/transfers", params: {
      from_wallet_id: @w1.id, to_wallet_id: @w2.id, amount: 999
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal before, Transaction.count
    assert_equal 100.0, @w1.reload.balance
    assert_equal 0.0, @w2.reload.balance
  end

  test "POST /transfers to the same wallet returns 422" do
    login_as(@user1)

    post "/transfers", params: {
      from_wallet_id: @w1.id, to_wallet_id: @w1.id, amount: 10
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "POST /transfers with missing source wallet returns 404" do
    login_as(@user1)
    post "/transfers", params: {
      from_wallet_id: 999999, to_wallet_id: @w2.id, amount: 10
    }, as: :json
    assert_response :not_found
  end

  test "POST /transfers without from_wallet_id returns 400" do
    login_as(@user1)
    post "/transfers", params: { to_wallet_id: @w2.id, amount: 10 }, as: :json
    assert_response :bad_request
  end
end