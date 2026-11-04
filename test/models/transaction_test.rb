require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    Transaction.delete_all
    Wallet.delete_all
    User.delete_all

    @u1 = User.create!(email: "m1@test.com", password: "secret123")
    @u2 = User.create!(email: "m2@test.com", password: "secret123")
    @w1 = @u1.wallet
    @w2 = @u2.wallet
  end

  # === CREDIT ===
  test "Credit is valid with nil source and present target" do
    assert Credit.new(amount: 10, target_wallet: @w1).valid?
  end

  test "Credit is invalid when source wallet is present" do
    t = Credit.new(amount: 10, source_wallet: @w2, target_wallet: @w1)
    assert_not t.valid?
    assert t.errors[:source_wallet].any?
  end

  test "Credit is invalid when target wallet is missing" do
    t = Credit.new(amount: 10)
    assert_not t.valid?
  end

  # === DEBIT ===
  test "Debit is valid with present source and nil target" do
    assert Debit.new(amount: 10, source_wallet: @w1).valid?
  end

  test "Debit is invalid when target wallet is present" do
    t = Debit.new(amount: 10, source_wallet: @w1, target_wallet: @w2)
    assert_not t.valid?
  end

  test "Debit is invalid when source wallet is missing" do
    t = Debit.new(amount: 10)
    assert_not t.valid?
  end

  # === TRANSFER ===
  test "Transfer is valid with distinct source and target wallets" do
    assert Transfer.new(amount: 10, source_wallet: @w1, target_wallet: @w2).valid?
  end

  test "Transfer is invalid when source equals target" do
    t = Transfer.new(amount: 10, source_wallet: @w1, target_wallet: @w1)
    assert_not t.valid?
    assert t.errors[:target_wallet].any?
  end

  test "Transfer is invalid when either wallet is missing" do
    assert_not Transfer.new(amount: 10, source_wallet: @w1).valid?
    assert_not Transfer.new(amount: 10, target_wallet: @w2).valid?
  end

  # === AMOUNT ===
  test "amount must be greater than zero" do
    assert_not Credit.new(amount: 0, target_wallet: @w1).valid?
    assert_not Credit.new(amount: -1, target_wallet: @w1).valid?
  end

  # === STI ===
  test "STI: all transaction types are stored in the transactions table" do
    Credit.create!(amount: 10, target_wallet: @w1)
    Debit.create!(amount: 5, source_wallet: @w1)
    Transfer.create!(amount: 3, source_wallet: @w1, target_wallet: @w2)

    assert_equal 3, Transaction.count
    assert_equal 1, Credit.count
    assert_equal 1, Debit.count
    assert_equal 1, Transfer.count
  end

  # === BALANCE ===
  test "Wallet#balance equals sum of credits minus sum of debits" do
    Credit.create!(amount: 100, target_wallet: @w1)
    Debit.create!(amount: 30, source_wallet: @w1)
    Transfer.create!(amount: 20, source_wallet: @w1, target_wallet: @w2)

    assert_equal 50, @w1.reload.balance
    assert_equal 20, @w2.reload.balance
  end
end