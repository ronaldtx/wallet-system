class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.string :walletable_type, null: false
      t.bigint :walletable_id, null: false
      t.timestamps
    end

    add_index :wallets, [:walletable_type, :walletable_id],
              unique: true,
              name: "index_wallets_on_walletable"
  end
end