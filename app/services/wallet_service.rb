class WalletService
  class Error < StandardError; end
  class InvalidAmountError < Error; end
  class InsufficientFundsError < Error; end
  class WalletNotFoundError < Error; end
  class SameWalletError < Error; end

  class << self
    # === DEPOSIT ===
    def deposit(wallet:, amount:, description: nil)
      validate_wallet!(wallet)
      validate_amount!(amount)

      ActiveRecord::Base.transaction do
        Credit.create!(
          amount: amount,
          target_wallet: wallet,
          description: description
        )
      end
    end

    # === WITHDRAW ===
    def withdraw(wallet:, amount:, description: nil)
      validate_wallet!(wallet)
      validate_amount!(amount)

      ActiveRecord::Base.transaction do
        wallet.lock!

        ensure_sufficient_funds!(wallet, amount)

        Debit.create!(
          amount: amount,
          source_wallet: wallet,
          description: description
        )
      end
    end

    # === TRANSFER ===
    def transfer(from_wallet:, to_wallet:, amount:, description: nil)
      validate_wallet!(from_wallet)
      validate_wallet!(to_wallet)
      validate_amount!(amount)

      if from_wallet.id == to_wallet.id
        raise SameWalletError, "Source and wallet target cannot be same"
      end

      ActiveRecord::Base.transaction do
        wallets_to_lock = [from_wallet, to_wallet].sort_by(&:id)
        wallets_to_lock.each(&:lock!)

        ensure_sufficient_funds!(from_wallet, amount)

        Transfer.create!(
          amount: amount,
          source_wallet: from_wallet,
          target_wallet: to_wallet,
          description: description
        )
      end
    end

    private

    # === VALIDATION ===
    def validate_wallet!(wallet)
      raise WalletNotFoundError, "Wallet not found" if wallet.nil?
    end

    def validate_amount!(amount)
      if amount.nil? || !amount.is_a?(Numeric) || amount <= 0
        raise InvalidAmountError, "Amount must be greater than 0"
      end
    end

    def ensure_sufficient_funds!(wallet, amount)
      if wallet.balance < amount
        raise InsufficientFundsError,
              "insufficient balance (balance: #{wallet.balance}, ask: #{amount})"
      end
    end
  end
end