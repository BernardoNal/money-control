class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.boolean :is_income
      t.string :icon
      t.string :color
      t.references :user, foreign_key: true, null: true
      t.timestamps
    end
  end
end
