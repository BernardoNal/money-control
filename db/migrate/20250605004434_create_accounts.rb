class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :bank
      t.decimal :initial_balance
      t.decimal :limit
      t.string :last_digits
      t.date :due_day
      t.string :card_type
      t.references :user, null: false, foreign_key: true


      t.timestamps
    end
  end
end
