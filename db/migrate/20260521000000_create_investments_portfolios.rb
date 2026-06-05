class CreateInvestmentsPortfolios < ActiveRecord::Migration[7.1]
  def change
    create_table :investments_portfolios do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :investments_portfolios, [:user_id, :name], unique: true
  end
end
