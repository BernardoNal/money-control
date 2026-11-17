require "rails_helper"

RSpec.describe BankInstitution, type: :model do
  subject(:institution) do
    described_class.new(
      bank_code: "001",
      ispb: "00000000",
      name: "Banco do Brasil S.A.",
      source: "bcb"
    )
  end

  it "is valid with the external code, name, and source" do
    expect(institution).to be_valid
  end

  it "requires the external code and name" do
    institution.bank_code = nil
    institution.name = nil

    expect(institution).not_to be_valid
    expect(institution.errors).to include(:bank_code, :name)
  end

  it "keeps external codes unique within a source" do
    described_class.create!(institution.attributes.except("id", "created_at", "updated_at"))
    duplicate = described_class.new(institution.attributes.except("id", "created_at", "updated_at"))

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:bank_code]).not_to be_empty
  end
end
