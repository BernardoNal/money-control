require "rails_helper"

RSpec.describe AccountPolicy, type: :policy do
  let(:user) do
    User.create!(
      name: "Policy User",
      email: "policy-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other Policy User",
      email: "other-policy-user@example.com",
      password: "password123"
    )
  end

  let(:account) do
    Account.create!(
      user: user,
      name: "User Account",
      bank: "Test Bank",
      initial_balance: 1000
    )
  end

  let(:other_account) do
    Account.create!(
      user: other_user,
      name: "Other Account",
      bank: "Other Bank",
      initial_balance: 500
    )
  end

 describe "record authorization" do
  subject(:policy) { described_class.new(user, account) }

  it "permits the owner to show the account" do
    expect(policy.show?).to be(true)
  end

  it "permits the owner to update the account" do
    expect(policy.update?).to be(true)
  end

  it "permits the owner to destroy the account" do
    expect(policy.destroy?).to be(true)
  end

  it "denies access to an account owned by another user" do
    policy = described_class.new(user, other_account)

    expect(policy.show?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end

  describe "Scope" do
    it "returns only accounts owned by the user" do
      account
      other_account

      resolved_accounts =
        described_class::Scope.new(user, Account.all).resolve

      expect(resolved_accounts).to contain_exactly(account)
    end
  end
end
