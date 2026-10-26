require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the TransactionsHelper. For example:
#
# describe TransactionsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe TransactionsHelper, type: :helper do
  it "hides default direction category labels" do
    expect(helper.transaction_category_label(double(name: "Sem categoria (Entrada)"))).to eq("--")
    expect(helper.transaction_category_label(double(name: "Sem categoria (Saída)"))).to eq("--")
  end

  it "keeps real category names" do
    expect(helper.transaction_category_label(double(name: "Mercado"))).to eq("Mercado")
    expect(helper.transaction_category_label(nil)).to eq("--")
  end
end
