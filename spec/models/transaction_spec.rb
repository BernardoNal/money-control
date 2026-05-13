require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:user) do
    User.create!(
      name: "Model User",
      email: "transaction-model@example.com",
      password: "password123"
    )
  end

  let(:account) do
    Account.create!(
      user: user,
      name: "Principal",
      bank: "Nubank",
      initial_balance: 100.0
    )
  end

  let(:category) do
    Category.create!(
      user: user,
      name: "Mercado",
      is_income: false,
      icon: "🛒",
      color: "#ff6600"
    )
  end

  subject(:transaction) do
    described_class.new(
      amount: 49.9,
      date: Date.current,
      description: "Compra do mes",
      account: account,
      category: category
    )
  end

  it "is valid with required attributes" do
    expect(transaction).to be_valid
  end

  it "is invalid without amount" do
    transaction.amount = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:amount]).to include("can't be blank")
  end

  it "is invalid without date" do
    transaction.date = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:date]).to include("can't be blank")
  end

  it "is invalid without description" do
    transaction.description = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:description]).to include("can't be blank")
  end

  it "is invalid without account" do
    transaction.account = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:account]).to include("must exist")
  end

  it "is invalid without category" do
    transaction.category = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:category]).to include("must exist")
  end
end
