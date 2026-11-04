class Credit < Transaction
  validate :source_wallet_must_be_nil
  validate :target_wallet_must_be_present

  private

  def source_wallet_must_be_nil
    if source_wallet_id.present?
      errors.add(:source_wallet, "Must empty for Credit")
    end
  end

  def target_wallet_must_be_present
    if target_wallet_id.blank?
      errors.add(:target_wallet, "Mandatory for Credit")
    end
  end
end