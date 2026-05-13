require 'rails_helper'

RSpec.describe "Transactions", type: :request do
  let(:user) do
    User.create!(
      name: "Request User",
      email: "transaction-request@example.com",
      password: "password123"
    )
  end

  let!(:account) do
    Account.create!(
      user: user,
      name: "Principal",
      bank: "Nubank",
      initial_balance: 100.0
    )
  end

  let!(:category) do
    Category.create!(
      user: user,
      name: "Mercado",
      is_income: false,
      icon: "🛒",
      color: "#ff6600"
    )
  end

  before do
    sign_in user
  end

  describe "POST /create" do
    it "does not persist an invalid transaction and displays validation errors" do
      expect do
        post transactions_path, params: {
          transaction: {
            amount: "",
            description: "",
            date: "",
            category_id: category.id
          }
        }
      end.not_to change(Transaction, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Nao foi possivel salvar a transacao").or include("Não foi possível salvar a transação")
      expect(response.body).to include("Amount can")
      expect(response.body).to include("Date can")
      expect(response.body).to include("Description can")
    end

    it "persists a valid transaction" do
      expect do
        post transactions_path, params: {
          transaction: {
            amount: 89.9,
            description: "Mercado do mes",
            date: Date.current,
            category_id: category.id
          }
        }
      end.to change(Transaction, :count).by(1)

      expect(response).to redirect_to(transaction_path(Transaction.last))
    end
  end
end
