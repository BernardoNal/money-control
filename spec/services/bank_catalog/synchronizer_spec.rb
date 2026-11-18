require "rails_helper"

RSpec.describe BankCatalog::Synchronizer do
  it "upserts valid records and keeps the last duplicate from the source" do
    result = described_class.call(
      records: [
        { bank_code: "001", name: "Banco do Brasil" },
        { bank_code: "001", name: "Banco do Brasil S.A.", short_name: "BB" },
        { bank_code: "077", name: "Banco Inter" }
      ],
      synced_at: Time.zone.parse("2026-11-17 10:00:00")
    )

    expect(result.upserted_count).to eq(2)
    expect(result.invalid_count).to eq(0)
    expect(BankInstitution.find_by(bank_code: "001").name).to eq("Banco do Brasil S.A.")
    expect(BankInstitution.find_by(bank_code: "001").short_name).to eq("BB")
  end

  it "ignores invalid records without partially persisting them" do
    result = described_class.call(
      records: [
        { bank_code: "001", name: "Banco do Brasil" },
        { bank_code: "", name: "Sem código" },
        { bank_code: "077", name: nil }
      ]
    )

    expect(result.upserted_count).to eq(1)
    expect(result.invalid_count).to eq(2)
    expect(BankInstitution.count).to eq(1)
  end

  it "accepts string keys from external JSON payloads" do
    described_class.call(
      records: [{ "bank_code" => "341", "name" => "Itaú Unibanco" }]
    )

    expect(BankInstitution.find_by(bank_code: "341").name).to eq("Itaú Unibanco")
  end
end
