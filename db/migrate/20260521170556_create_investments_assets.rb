class CreateInvestmentsAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :investments_assets do |t|
      t.string :name, null: false
      t.string :symbol, null: false
      t.integer :category, null: false
      t.string :currency, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :investments_assets, :symbol, unique: true
  end
end
