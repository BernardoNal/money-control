class RequireBankInstitutionOnAccounts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :accounts, :bank_institution_id, false
  end
end
