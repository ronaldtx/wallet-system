class Debit < Transaction
  validate :source_wallet_must_be_present
  validate :target_wallet_must_be_nil

  private

  def source_wallet_must_be_present
    if source_wallet_id.blank?
      errors.add(:source_wallet, "Mandatory for Debit")
    end
  end

  def target_wallet_must_be_nil
    if target_wallet_id.present?
      errors.add(:target_wallet, "Must empty for Debit")
    end
  end
end