class Transfer < Transaction
  validate :source_wallet_must_be_present
  validate :target_wallet_must_be_present
  validate :wallets_must_differ

  private

  def source_wallet_must_be_present
    if source_wallet_id.blank?
      errors.add(:source_wallet, "Mandatory for Transfer")
    end
  end

  def target_wallet_must_be_present
    if target_wallet_id.blank?
      errors.add(:target_wallet, "Mandatory for Transfer")
    end
  end

  def wallets_must_differ
    if source_wallet_id.present? && source_wallet_id == target_wallet_id
      errors.add(:target_wallet, "Cannot same with source wallet")
    end
  end
end