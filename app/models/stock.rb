class Stock < ApplicationRecord
  has_one :wallet, as: :walletable, dependent: :destroy
  validates :symbol, presence: true, uniqueness: { case_sensitive: false }
  after_create :create_wallet!

  private

  def create_wallet!
    create_wallet
  end
end