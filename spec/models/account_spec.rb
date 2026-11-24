require "rails_helper"

RSpec.describe Account, type: :model do
  it "requires a bank institution" do
    user = User.create!(name: "Account Owner", email: "account-owner@example.com", password: "password123")
    bank_institution = BankInstitution.create!(bank_code: "001", name: "Banco do Brasil", source: "bcb")
    account = described_class.create!(
      user: user,
      name: "Principal",
      bank_institution: bank_institution,
      initial_balance: 0
    )

    expect(account.bank_institution).to eq(bank_institution)
    expect(account.bank_display_name).to eq("Banco do Brasil")
  end

  it "is invalid without a bank institution" do
    user = User.create!(name: "Legacy Owner", email: "legacy-owner@example.com", password: "password123")

    account = described_class.new(
      user: user,
      name: "Legacy account",
      initial_balance: 0
    )

    expect(account).not_to be_valid
    expect(account.errors[:bank_institution]).to include("é obrigatório")
  end
end
