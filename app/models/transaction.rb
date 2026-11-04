class Transaction < ApplicationRecord
  belongs_to :source_wallet, class_name: "Wallet", optional: true
  belongs_to :target_wallet, class_name: "Wallet", optional: true
  validates :amount, presence: true,
                     numericality: { greater_than: 0 }
  validate :must_have_at_least_one_wallet

  private

  def must_have_at_least_one_wallet
    if source_wallet_id.nil? && target_wallet_id.nil?
      errors.add(:base, "Transaction must have source or target wallet")
    end
  end
end