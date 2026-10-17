class AddImportMetadataToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_reference :transactions, :transaction_import, foreign_key: true
    add_column :transactions, :source_document_number, :string
    add_column :transactions, :import_fingerprint, :string
    add_index :transactions, %i[account_id import_fingerprint]
  end
end
