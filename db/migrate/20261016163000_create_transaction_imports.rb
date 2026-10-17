class CreateTransactionImports < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_imports do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :original_filename, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :rows, null: false, default: []
      t.jsonb :summary, null: false, default: {}
      t.datetime :expires_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :transaction_imports, %i[account_id status]
  end
end
