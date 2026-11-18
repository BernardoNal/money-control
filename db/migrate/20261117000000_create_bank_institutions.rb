class CreateBankInstitutions < ActiveRecord::Migration[7.1]
  def change
    create_table :bank_institutions do |t|
      t.string :bank_code, null: false
      t.string :ispb
      t.string :name, null: false
      t.string :short_name
      t.string :institution_type
      t.string :source, null: false, default: "bcb"
      t.boolean :active, null: false, default: true
      t.datetime :source_updated_at
      t.timestamps

      t.index %i[source bank_code], unique: true
      t.index :ispb
      t.index :active
    end
  end
end
