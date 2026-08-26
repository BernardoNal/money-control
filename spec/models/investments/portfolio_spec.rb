require "rails_helper"

RSpec.describe Investments::Portfolio, type: :model do
  let(:user) do
    User.create!(
      name: "Investor",
      email: "investor@example.com",
      password: "password123"
    )
  end

  subject(:portfolio) do
    described_class.new(
      user: user,
      name: "Main Portfolio"
    )
  end

  it "is valid with required attributes" do
    expect(portfolio).to be_valid
  end

  it "is invalid without a name" do
    portfolio.name = nil

    expect(portfolio).not_to be_valid
    expect(portfolio.errors[:name]).to include( I18n.t("activerecord.errors.messages.blank"))
  end

  it "is invalid without a user" do
    portfolio.user = nil

    expect(portfolio).not_to be_valid
    expect(portfolio.errors[:user]).to include( I18n.t("activerecord.errors.messages.required"))
  end

  it "does not allow duplicate names for the same user" do
    described_class.create!(user: user, name: "Main Portfolio")

    expect(portfolio).not_to be_valid
    expect(portfolio.errors[:name]).to include( I18n.t("activerecord.errors.messages.taken"))
  end

  it "allows the same name for different users" do
    other_user = User.create!(
      name: "Other Investor",
      email: "other-investor@example.com",
      password: "password123"
    )

    described_class.create!(user: user, name: "Main Portfolio")
    other_portfolio = described_class.new(user: other_user, name: "Main Portfolio")

    expect(other_portfolio).to be_valid
  end
end
