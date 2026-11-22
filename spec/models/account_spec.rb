require "rails_helper"

RSpec.describe Account, type: :model do
  it "can reference a bank institution while retaining legacy bank data" do
    user = User.create!(name: "Account Owner", email: "account-owner@example.com", password: "password123")
    bank_institution = BankInstitution.create!(bank_code: "001", name: "Banco do Brasil", source: "bcb")
    account = described_class.create!(
      user: user,
      name: "Principal",
      bank: "Banco do Brasil",
      bank_institution: bank_institution,
      initial_balance: 0
    )

    expect(account.bank_institution).to eq(bank_institution)
    expect(account.bank).to eq("Banco do Brasil")
  end

  it "keeps the bank institution optional during the additive migration" do
    user = User.create!(name: "Legacy Owner", email: "legacy-owner@example.com", password: "password123")

    account = described_class.create!(
      user: user,
      name: "Legacy account",
      bank: "Legacy Bank",
      initial_balance: 0
    )

    expect(account.bank_institution).to be_nil
  end
end
