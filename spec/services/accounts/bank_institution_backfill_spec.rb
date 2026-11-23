require "rails_helper"

RSpec.describe Accounts::BankInstitutionBackfill do
  let(:user) do
    User.create!(name: "Account Owner", email: "account-owner@example.com", password: "password123")
  end

  def create_account(bank)
    Account.create!(user: user, name: bank, bank: bank, initial_balance: 0)
  end

  it "matches unique normalized names and short names" do
    institution = BankInstitution.create!(bank_code: "001", name: "Banco do Brasil S.A.", short_name: "BCO DO BRASIL S.A.")
    account = create_account("bco do brasil s.a.")

    result = described_class.call

    expect(result.matched.map { |entry| entry[:account] }).to eq([account])
    expect(result.ambiguous).to be_empty
    expect(result.unmatched).to be_empty
    expect(account.reload.bank_institution).to be_nil
    expect(result.matched.first[:bank_institution]).to eq(institution)
  end

  it "does not assign a bank when the normalized name has no candidate" do
    BankInstitution.create!(bank_code: "336", name: "Banco C6 S.A.", short_name: "BCO C6 S.A.")
    BankInstitution.create!(bank_code: "626", name: "Banco C6 Consignado S.A.", short_name: "BCO C6 CONSIG")
    account = create_account("C6Bank")

    result = described_class.call

    expect(result.ambiguous).to be_empty
    expect(result.unmatched.map { |entry| entry[:account] }).to eq([account])
    expect(account.reload.bank_institution).to be_nil
  end

  it "reports ambiguous exact catalog values without assigning them" do
    BankInstitution.create!(bank_code: "001", name: "Banco do Brasil", short_name: "BB")
    BankInstitution.create!(bank_code: "002", name: "Outro Banco", short_name: "BB")
    account = create_account("BB")

    result = described_class.call

    expect(result.ambiguous.map { |entry| entry[:account] }).to eq([account])
    expect(result.ambiguous.first[:candidates].size).to eq(2)
    expect(account.reload.bank_institution).to be_nil
  end

  it "applies only unique matches when explicitly requested" do
    institution = BankInstitution.create!(bank_code: "260", name: "Nu Pagamentos S.A.", short_name: "NU PAGAMENTOS - IP")
    account = create_account("NU PAGAMENTOS - IP")

    described_class.call(apply: true)

    expect(account.reload.bank_institution).to eq(institution)
  end
end
