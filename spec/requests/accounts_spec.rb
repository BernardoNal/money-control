require "rails_helper"

RSpec.describe "Accounts", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "user@example.com",
      password: "password123"
    )
  end

  let!(:account) do
    Account.create!(
      user: user,
      name: "Principal",
      bank: "Nubank",
      initial_balance: 100.0,
      limit: 500.0,
      last_digits: "1234",
      due_day: Date.current
    )
  end

  before do
    sign_in user
  end

  describe "GET /new" do
    it "renders the new account form" do
      get new_account_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates an account for the current user" do
      expect do
        post accounts_path, params: {
          account: {
            name: "Investimentos",
            bank: "Inter",
            initial_balance: 1000.0,
            limit: 500.0,
            last_digits: "5678",
            due_day: Date.current
          }
        }
      end.to change(Account, :count).by(1)

      created_account = Account.order(:created_at).last

      expect(created_account.user).to eq(user)
      expect(response).to redirect_to(account_path(created_account))
    end
  end

  describe "PATCH /update" do
    it "updates the existing account without creating a new record" do
      expect do
        patch account_path(account), params: {
          account: {
            name: "Reserva",
            bank: "Inter",
            initial_balance: 250.0
          }
        }
      end.not_to change(Account, :count)

      expect(response).to redirect_to(account_path(account))

      account.reload
      expect(account.name).to eq("Reserva")
      expect(account.bank).to eq("Inter")
      expect(account.initial_balance.to_f).to eq(250.0)
    end

    it "renders edit when the update is invalid" do
      patch account_path(account), params: {
        account: {
          name: "",
          bank: "",
          initial_balance: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)

      account.reload
      expect(account.name).to eq("Principal")
      expect(account.bank).to eq("Nubank")
    end
  end

  describe "authorization" do
    let(:other_user) do
      User.create!(
        name: "Other User",
        email: "other@example.com",
        password: "password123"
      )
    end

    let!(:other_account) do
      Account.create!(
        user: other_user,
        name: "Other Account",
        bank: "Inter",
        initial_balance: 500.0,
        limit: 1000.0,
        last_digits: "5678",
        due_day: Date.current
      )
    end

   it "does not expose another user's account" do
      get account_path(other_account)

      expect(response).to redirect_to(root_path)
    end
  end
end
