class RemoveLegacyBankFromAccounts < ActiveRecord::Migration[7.1]
  def change
    remove_column :accounts, :bank, :string
  end
end
