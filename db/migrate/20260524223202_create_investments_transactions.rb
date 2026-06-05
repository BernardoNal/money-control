class CreateInvestmentsTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :investments_transactions do |t|
      t.references :portfolio, null: false, foreign_key: { to_table: :investments_portfolios }
      t.references :asset, null: false, foreign_key: { to_table: :investments_assets }
      t.integer :transaction_type, null: false
      t.decimal :quantity, null: false, precision: 15, scale: 8
      t.decimal :price, precision: 15, scale: 4
      t.decimal :fees, precision: 15, scale: 4, default: 0, null: false
      t.date :date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :investments_transactions, :date
  end
end
