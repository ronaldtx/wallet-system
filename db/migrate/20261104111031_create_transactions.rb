class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :type, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.bigint :source_wallet_id, null: true
      t.bigint :target_wallet_id, null: true
      t.string :description
      t.timestamps
    end

    add_index :transactions, :source_wallet_id
    add_index :transactions, :target_wallet_id
    add_index :transactions, :type

    add_foreign_key :transactions, :wallets, column: :source_wallet_id
    add_foreign_key :transactions, :wallets, column: :target_wallet_id

    execute <<~SQL
      ALTER TABLE transactions
      ADD CONSTRAINT amount_positive CHECK (amount > 0)
    SQL
  end
end