class WalletsController < ApplicationController
	before_action :authenticate_user!
	before_action :set_wallet, only: [:show, :transactions, :deposit, :withdraw]

	# GET /wallets/:id
	def show
		render json: wallet_json(@wallet), status: :ok
	end

	# GET /wallets/:id/transactions
	def transactions
		txns = Transaction
		       .where("source_wallet_id = :id OR target_wallet_id = :id", id: @wallet.id)
		       .order(created_at: :desc)
		       .limit(100)  # batasi, bisa paginate nanti

		render json: txns.map { |t| transaction_json(t) }, status: :ok
	end

	# POST /wallets/:id/deposit
	def deposit
		amount = params.require(:amount)

		txn = WalletService.deposit(
		  wallet: @wallet,
		  amount: amount,
		  description: params[:description]
		)

		render json: {
		  message: "Deposit berhasil",
		  transaction: transaction_json(txn),
		  balance: @wallet.reload.balance.to_f
		}, status: :created

		rescue WalletService::InvalidAmountError,
		     WalletService::WalletNotFoundError => e
		render_service_error(e, status: :unprocessable_entity)
	end

	# POST /wallets/:id/withdraw
	def withdraw
		amount = params.require(:amount)

		txn = WalletService.withdraw(
		  wallet: @wallet,
		  amount: amount,
		  description: params[:description]
		)

		render json: {
		  message: "Withdraw berhasil",
		  transaction: transaction_json(txn),
		  balance: @wallet.reload.balance.to_f
		}, status: :created

		rescue WalletService::InvalidAmountError,
		     WalletService::WalletNotFoundError => e
		render_service_error(e, status: :unprocessable_entity)
		rescue WalletService::InsufficientFundsError => e
		render_service_error(e, status: :unprocessable_entity)
	end

	private

	def set_wallet
		@wallet = Wallet.find(params[:id])
	end

	def wallet_json(wallet)
		{
			id: wallet.id,
			balance: wallet.balance.to_f,
			owner_type: wallet.walletable_type,
			owner_id: wallet.walletable_id,
			owner: wallet_owner_json(wallet.walletable)
		}
	end

	def wallet_owner_json(owner)
		case owner
		when User
			{ id: owner.id, email: owner.email }
		when Team
			{ id: owner.id, name: owner.name }
		when Stock
			{ id: owner.id, symbol: owner.symbol, name: owner.name }
		else
			{ id: owner.id }
		end
	end

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