class Wallet < ApplicationRecord
  belongs_to :walletable, polymorphic: true
  has_many :outgoing_transactions,
           class_name: "Transaction",
           foreign_key: :source_wallet_id,
           dependent: :restrict_with_error,
           inverse_of: :source_wallet
  has_many :incoming_transactions,
           class_name: "Transaction",
           foreign_key: :target_wallet_id,
           dependent: :restrict_with_error,
           inverse_of: :target_wallet

  def balance
    incoming = incoming_transactions.sum(:amount)
    outgoing = outgoing_transactions.sum(:amount)
    incoming - outgoing
  end
end