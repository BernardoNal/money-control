require "rails_helper"

RSpec.describe Investments::IncomeTaxReportPdf do
  let(:report) do
    Investments::IncomeTaxReportBuilder.call(
      incomes: Investments::Income.where(portfolio: portfolio),
      year: 2026
    )
  end

  let(:user) do
    User.create!(
      name: "PDF User",
      email: "pdf-user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(name: "PDF Portfolio", user: user)
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "Fundo Brasileiro",
      symbol: "FBR11",
      category: :fii,
      currency: "BRL"
    )
  end

  it "returns a PDF document for a populated report" do
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 100,
      tax_amount: 10,
      payment_date: Date.new(2026, 2, 10)
    )

    pdf = described_class.call(report: report, user: user)

    expect(pdf).to start_with("%PDF")
    expect(pdf).to include("%%EOF")
  end

  it "returns a PDF document for an empty report" do
    pdf = described_class.call(report: report, user: user)

    expect(pdf).to start_with("%PDF")
    expect(pdf).to include("%%EOF")
  end
end
