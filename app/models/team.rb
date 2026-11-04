class Team < ApplicationRecord
  has_one :wallet, as: :walletable, dependent: :destroy
  validates :name, presence: true
  after_create :create_wallet!

  private

  def create_wallet!
    create_wallet
  end
end