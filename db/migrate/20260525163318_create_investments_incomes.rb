class CreateInvestmentsIncomes < ActiveRecord::Migration[7.1]
  def change
    create_table :investments_incomes do |t|
      t.references :portfolio, null: false, foreign_key: { to_table: :investments_portfolios }
      t.references :asset, null: false, foreign_key: { to_table: :investments_assets }
      t.integer :income_type, null: false
      t.decimal :gross_amount, null: false, precision: 15, scale: 4
      t.decimal :net_amount, null: false, precision: 15, scale: 4
      t.decimal :tax_amount, null: false, default: 0, precision: 15, scale: 4
      t.date :payment_date, null: false
      t.date :reference_date
      t.text :notes

      t.timestamps
    end

    add_index :investments_incomes, :payment_date
  end
end
