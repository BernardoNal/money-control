class AddSubcategoryToInvestmentsAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :investments_assets, :subcategory, :integer
  end
end
