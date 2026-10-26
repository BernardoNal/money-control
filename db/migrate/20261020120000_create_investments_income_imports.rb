class CreateInvestmentsIncomeImports < ActiveRecord::Migration[7.1]
  def change
    create_table :investments_income_imports do |t|
      t.references :portfolio, null: false, foreign_key: { to_table: :investments_portfolios }, index: true
      t.string :original_filename, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :rows, null: false, default: []
      t.jsonb :summary, null: false, default: {}
      t.datetime :expires_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :investments_income_imports, %i[portfolio_id status]
  end
end
