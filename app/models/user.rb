class User < ApplicationRecord
  has_secure_password
  has_one :wallet, as: :walletable, dependent: :destroy
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, allow_nil: true
  after_create :create_wallet!

  private

  def create_wallet!
    create_wallet
  end
end