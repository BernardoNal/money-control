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

  let(:other_user) do
    User.create!(
      name: "Other User",
      email: "other-transaction@example.com",
      password: "password123"
    )
  end

  let(:other_account) do
    Account.create!(
      user: other_user,
      name: "Outra Conta",
      bank: "Nubank",
      initial_balance: 100.0
    )
  end

  let(:other_transaction) do
  Transaction.create!(
    account: other_account,
    category: category,
    amount: 50,
    description: "Outra transação",
    date: Date.current
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

  describe "GET /show" do
    it "allows access to a transaction owned by the current user" do
      transaction = Transaction.create!(
        account: account,
        category: category,
        amount: 100,
        description: "Minha transação",
        date: Date.current
      )

      get transaction_path(transaction)

      expect(response).to have_http_status(:ok)
    end

    it "does not expose another user's transaction" do
      get transaction_path(other_transaction)

      expect(response).to redirect_to(root_path)
    end

    it "redirects with a friendly alert when the transaction does not exist" do
      get transaction_path(999_999)

      expect(response).to redirect_to(transactions_path)
      expect(flash[:alert]).to eq("Registro nao encontrado ou indisponivel.")
    end
  end

  describe "POST /create" do
    it "does not persist an invalid transaction and displays validation errors" do
      expect do
        post transactions_path, params: {
          transaction: {
            account_id: account.id,
            amount: "",
            description: "",
            date: "",
            category_id: category.id
          }
        }
      end.not_to change(Transaction, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(
        "Nao foi possivel salvar a transacao"
      ).or include(
        "Não foi possível salvar a transação"
      )
      expect(response.body).to include("Amount não pode ficar em branco")
      expect(response.body).to include("Date não pode ficar em branco")
      expect(response.body).to include("Description não pode ficar em branco")
    end

    it "persists a valid transaction" do
      expect do
        post transactions_path, params: {
          transaction: {
            account_id: account.id,
            amount: 89.9,
            description: "Mercado do mes",
            date: Date.current,
            category_id: category.id
          }
        }
      end.to change(Transaction, :count).by(1)

      expect(response).to redirect_to(transaction_path(Transaction.last))
    end

    it "does not allow creating a transaction in another user's account" do
      expect do
        post transactions_path, params: {
          transaction: {
            amount: 100,
            description: "Transação indevida",
            date: Date.current,
            category_id: category.id,
            account_id: other_account.id
          }
        }
      end.not_to change(Transaction, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /update" do
    it "allows updating a transaction owned by the current user" do
      transaction = Transaction.create!(
        account: account,
        category: category,
        amount: 100,
        description: "Minha transação",
        date: Date.current
      )

      patch transaction_path(transaction), params: {
        transaction: {
          amount: 150
        }
      }

      expect(response).to redirect_to(transaction_path(transaction))
      expect(transaction.reload.amount).to eq(150)
    end

    it "does not allow updating another user's transaction" do
      patch transaction_path(other_transaction), params: {
        transaction: {
          amount: 999
        }
      }

      expect(response).to redirect_to(root_path)

      other_transaction.reload
      expect(other_transaction.amount).to eq(50)
    end
  end

  describe "DELETE /destroy" do
    it "allows destroying a transaction owned by the current user" do
      transaction = Transaction.create!(
        account: account,
        category: category,
        amount: 100,
        description: "Minha transação",
        date: Date.current
      )

      expect do
        delete transaction_path(transaction)
      end.to change(Transaction, :count).by(-1)

      expect(response).to redirect_to(transactions_path)
    end

    it "does not allow destroying another user's transaction" do
      other_transaction

      expect do
        delete transaction_path(other_transaction)
      end.not_to change(Transaction, :count)

      expect(response).to redirect_to(root_path)
      expect(Transaction.exists?(other_transaction.id)).to be(true)
    end
  end
end
