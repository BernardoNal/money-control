class AddSourceIdentifierToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :source_identifier, :string
    add_index :transactions, %i[account_id source_identifier]
  end
end
