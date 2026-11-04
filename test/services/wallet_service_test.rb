require "test_helper"

class WalletServiceTest < ActiveSupport::TestCase
  def setup
    Transaction.delete_all
    Wallet.delete_all
    User.delete_all

    @u1 = User.create!(email: "svc1@test.com", password: "secret123")
    @u2 = User.create!(email: "svc2@test.com", password: "secret123")
    @w1 = @u1.wallet
    @w2 = @u2.wallet
  end

  # === DEPOSIT ===
  test "deposit increases balance and creates a Credit" do
    txn = WalletService.deposit(wallet: @w1, amount: 100)

    assert_instance_of Credit, txn
    assert_equal 100, txn.amount
    assert_nil txn.source_wallet_id
    assert_equal @w1.id, txn.target_wallet_id
    assert_equal 100, @w1.reload.balance
  end

  test "deposit rejects zero and negative amounts" do
    assert_raises(WalletService::InvalidAmountError) do
      WalletService.deposit(wallet: @w1, amount: 0)
    end
    assert_raises(WalletService::InvalidAmountError) do
      WalletService.deposit(wallet: @w1, amount: -10)
    end
    assert_equal 0, @w1.reload.balance
    assert_equal 0, Transaction.count
  end

  test "deposit rejects nil wallet" do
    assert_raises(WalletService::WalletNotFoundError) do
      WalletService.deposit(wallet: nil, amount: 100)
    end
  end

  # === WITHDRAW ===
  test "withdraw decreases balance and creates a Debit" do
    WalletService.deposit(wallet: @w1, amount: 100)
    txn = WalletService.withdraw(wallet: @w1, amount: 30)

    assert_instance_of Debit, txn
    assert_equal 30, txn.amount
    assert_equal @w1.id, txn.source_wallet_id
    assert_nil txn.target_wallet_id
    assert_equal 70, @w1.reload.balance
  end

  test "withdraw with insufficient funds raises and rolls back" do
    WalletService.deposit(wallet: @w1, amount: 50)
    before_count = @w1.outgoing_transactions.count

    assert_raises(WalletService::InsufficientFundsError) do
      WalletService.withdraw(wallet: @w1, amount: 999)
    end

    assert_equal before_count, @w1.reload.outgoing_transactions.count
    assert_equal 50, @w1.balance
  end

  # === TRANSFER ===
  test "transfer moves balance between wallets" do
    WalletService.deposit(wallet: @w1, amount: 100)
    txn = WalletService.transfer(from_wallet: @w1, to_wallet: @w2, amount: 40)

    assert_instance_of Transfer, txn
    assert_equal @w1.id, txn.source_wallet_id
    assert_equal @w2.id, txn.target_wallet_id
    assert_equal 60, @w1.reload.balance
    assert_equal 40, @w2.reload.balance
  end

  test "transfer with insufficient funds raises and rolls back" do
    WalletService.deposit(wallet: @w1, amount: 50)
    before = Transaction.count

    assert_raises(WalletService::InsufficientFundsError) do
      WalletService.transfer(from_wallet: @w1, to_wallet: @w2, amount: 999)
    end

    assert_equal before, Transaction.count
    assert_equal 50, @w1.reload.balance
    assert_equal 0, @w2.reload.balance
  end

  test "transfer to the same wallet raises SameWalletError" do
    WalletService.deposit(wallet: @w1, amount: 100)

    assert_raises(WalletService::SameWalletError) do
      WalletService.transfer(from_wallet: @w1, to_wallet: @w1, amount: 10)
    end
    assert_equal 100, @w1.reload.balance
  end

  # === ACID ===
  test "ACID: failed transaction leaves no orphan records" do
    WalletService.deposit(wallet: @w1, amount: 100)
    initial_txn_count = Transaction.count

    assert_raises(WalletService::InsufficientFundsError) do
      WalletService.transfer(from_wallet: @w1, to_wallet: @w2, amount: 999)
    end

    assert_equal initial_txn_count, Transaction.count
    assert_equal 100, @w1.reload.balance
    assert_equal 0, @w2.reload.balance
  end

  test "ACID: failed withdraw does not reduce balance" do
    WalletService.deposit(wallet: @w1, amount: 50)

    assert_raises(WalletService::InsufficientFundsError) do
      WalletService.withdraw(wallet: @w1, amount: 51)
    end

    assert_equal 50, @w1.reload.balance
  end

  # === CONCURRENCY (advanced, optional) ===
  test "lock: two concurrent withdrawals never overdraw the wallet" do
    WalletService.deposit(wallet: @w1, amount: 100)

    results = []
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          WalletService.withdraw(wallet: @w1, amount: 80)
          results << :ok
        rescue WalletService::InsufficientFundsError
          results << :rejected
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, results.count(:ok), "Only one withdraw should succeed"
    assert_equal 1, results.count(:rejected), "One withdraw must be rejected"
    assert_equal 20, @w1.reload.balance
  end
end