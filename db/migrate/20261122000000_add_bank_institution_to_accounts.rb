class AddBankInstitutionToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_reference :accounts, :bank_institution, foreign_key: true, index: true
  end
end
