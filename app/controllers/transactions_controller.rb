class TransactionsController < ApplicationController
  before_action :authenticate_user!

  # POST /transfers
  def create
    from_wallet_id = params.require(:from_wallet_id)
    to_wallet_id   = params.require(:to_wallet_id)
    amount         = params.require(:amount)

    from_wallet = Wallet.find(from_wallet_id)
    to_wallet   = Wallet.find(to_wallet_id)

    txn = WalletService.transfer(
      from_wallet: from_wallet,
      to_wallet: to_wallet,
      amount: amount,
      description: params[:description]
    )

    render json: {
      message: "Transfer berhasil",
      transaction: transaction_json(txn),
      from_wallet: { id: from_wallet.id, balance: from_wallet.reload.balance.to_f },
      to_wallet:   { id: to_wallet.id,   balance: to_wallet.reload.balance.to_f }
    }, status: :created

  rescue WalletService::InvalidAmountError,
         WalletService::WalletNotFoundError,
         WalletService::SameWalletError => e
    render_service_error(e, status: :unprocessable_entity)
  rescue WalletService::InsufficientFundsError => e
    render_service_error(e, status: :unprocessable_entity)
  end

  private

  def transaction_json(t)
    {
      id: t.id,
      type: t.type,
      amount: t.amount.to_f,
      source_wallet_id: t.source_wallet_id,
      target_wallet_id: t.target_wallet_id,
      description: t.description,
      created_at: t.created_at
    }
  end
end