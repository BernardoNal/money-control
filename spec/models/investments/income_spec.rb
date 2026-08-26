require "rails_helper"

RSpec.describe Investments::Income, type: :model do
  let(:user) do
    User.create!(
      name: "Income Investor",
      email: "income-investor@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Income Portfolio"
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "Itausa",
      symbol: "ITSA4",
      category: :stock,
      currency: "BRL"
    )
  end

  subject(:income) do
    described_class.new(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 100.0,
      net_amount: 85.0,
      tax_amount: 15.0,
      payment_date: Date.current,
      reference_date: Date.current - 5.days,
      notes: "Quarterly distribution"
    )
  end

  it "is valid with required attributes" do
    expect(income).to be_valid
  end

  it "belongs to a portfolio" do
    income.portfolio = nil

    expect(income).not_to be_valid
    expect(income.errors[:portfolio]).to include(
      I18n.t("activerecord.errors.messages.required")
    )
  end

  it "belongs to an asset" do
    income.asset = nil

    expect(income).not_to be_valid
    expect(income.errors[:asset]).to include(
      I18n.t("activerecord.errors.messages.required")
    )
  end

  it "is invalid without an income type" do
    income.income_type = nil

    expect(income).not_to be_valid
    expect(income.errors[:income_type]).to include(
      I18n.t("activerecord.errors.messages.blank")
    )
  end

  it "is invalid without gross amount" do
    income.gross_amount = nil

    expect(income).not_to be_valid
    expect(income.errors[:gross_amount]).to include(
      I18n.t("activerecord.errors.messages.blank")
    )
  end

  it "is invalid when gross amount is negative" do
    income.gross_amount = -1

    expect(income).not_to be_valid
    expect(income.errors[:gross_amount]).to include(
      I18n.t(
        "activerecord.errors.messages.greater_than_or_equal_to",
        count: 0
      )
    )
  end

  it "calculates net amount from gross amount and tax amount" do
    income.gross_amount = 100.0
    income.tax_amount = 15.0

    expect(income).to be_valid
    expect(income.net_amount).to eq(85.0)
  end

  it "is invalid when tax amount is negative" do
    income.tax_amount = -1

    expect(income).not_to be_valid
    expect(income.errors[:tax_amount]).to include(
      I18n.t(
        "activerecord.errors.messages.greater_than_or_equal_to",
        count: 0
      )
    )
  end

  it "is invalid without payment date" do
    income.payment_date = nil

    expect(income).not_to be_valid
    expect(income.errors[:payment_date]).to include(
      I18n.t("activerecord.errors.messages.blank")
    )
  end

  it "is invalid when tax amount is greater than gross amount" do
    income.tax_amount = 120.0

    expect(income).not_to be_valid
    expect(income.net_amount).to eq(-20.0)
  end

  it "defines the expected income types" do
    expect(described_class.income_types.keys).to contain_exactly(
      "dividends",
      "jcp",
      "stock_lending",
      "fii_income",
      "amortization",
      "staking"
    )
  end
end
