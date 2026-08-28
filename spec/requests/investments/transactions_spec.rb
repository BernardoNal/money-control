require "rails_helper"

RSpec.describe "Investments::Transactions", type: :request do
  let(:user) do
    User.create!(
      name: "Transaction User",
      email: "transaction-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other User",
      email: "other-transaction-user@example.com",
      password: "password123"
    )
  end

  let!(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Main Portfolio"
    )
  end

  let!(:other_portfolio) do
    Investments::Portfolio.create!(
      user: other_user,
      name: "Other Portfolio"
    )
  end

  let!(:asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      subcategory: :technology,
      currency: "USD"
    )
  end

  let!(:transaction) do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 10,
      price: 100,
      date: Date.current
    )
  end

  let!(:other_transaction) do
    Investments::Transaction.create!(
      portfolio: other_portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 5,
      price: 100,
      date: Date.current
    )
  end

  before do
    sign_in user
  end

  describe "GET /index" do
    it "lists only transactions from the current user's portfolios" do
      get investments_transactions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end
  end

  describe "GET /show" do
    it "allows access to a transaction owned by the current user" do
      get investments_transaction_path(transaction)
      expect(response).to have_http_status(:ok)
    end

    it "does not expose another user's transaction" do
      get investments_transaction_path(other_transaction)
      expect(response).to redirect_to(root_path)
    end

    it "redirects with a friendly alert when the transaction does not exist" do
      get investments_transaction_path(999_999)

      expect(response).to redirect_to(investments_transactions_path)
      expect(flash[:alert]).to eq("Registro não encontrado ou indisponivel.")
    end
  end

  describe "POST /create" do
    it "creates a transaction in the current user's portfolio" do
      expect do
        post investments_transactions_path, params: {
          investments_transaction: {
            portfolio_id: portfolio.id,
            asset_id: asset.id,
            transaction_type: "buy",
            quantity: 10,
            price: 100,
            fees: 5,
            date: Date.current,
            notes: "Compra de teste"
          }
        }
      end.to change(Investments::Transaction, :count).by(1)

      transaction = Investments::Transaction.order(:created_at).last

      expect(response).to redirect_to(investments_transaction_path(transaction))
      expect(transaction.portfolio).to eq(portfolio)
      expect(transaction.asset).to eq(asset)
      expect(transaction.transaction_type).to eq("buy")
      expect(transaction.quantity).to eq(10)
      expect(transaction.price).to eq(100)
    end

    it "does not allow creating a transaction in another user's portfolio" do
      expect do
        post investments_transactions_path, params: {
          investments_transaction: {
            portfolio_id: other_portfolio.id,
            asset_id: asset.id,
            transaction_type: "buy",
            quantity: 10,
            price: 100,
            date: Date.current
          }
        }
      end.not_to change(Investments::Transaction, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /edit" do
    it "allows editing a transaction owned by the current user" do
      get edit_investments_transaction_path(transaction)

      expect(response).to have_http_status(:ok)
    end

    it "does not expose the edit form for another user's transaction" do
      get edit_investments_transaction_path(other_transaction)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /update" do
    it "updates a transaction owned by the current user" do
      expect do
        patch investments_transaction_path(transaction), params: {
          investments_transaction: {
            quantity: 20,
            price: 110,
            notes: "Compra atualizada"
          }
        }
      end.not_to change(Investments::Transaction, :count)

      expect(response).to redirect_to(
        investments_transaction_path(transaction)
      )

      transaction.reload

      expect(transaction.quantity).to eq(20)
      expect(transaction.price).to eq(110)
      expect(transaction.notes).to eq("Compra atualizada")
    end

    it "does not allow updating another user's transaction" do
      patch investments_transaction_path(other_transaction), params: {
        investments_transaction: {
          quantity: 999,
          price: 999
        }
      }

      expect(response).to redirect_to(root_path)

      other_transaction.reload

      expect(other_transaction.quantity).to eq(5)
      expect(other_transaction.price).to eq(100)
    end
  end

  describe "DELETE /destroy" do
    it "destroys a transaction owned by the current user" do
      expect do
        delete investments_transaction_path(transaction)
      end.to change(Investments::Transaction, :count).by(-1)

      expect(response).to redirect_to(investments_transactions_path)
    end

    it "does not allow destroying another user's transaction" do
      expect do
        delete investments_transaction_path(other_transaction)
      end.not_to change(Investments::Transaction, :count)

      expect(response).to redirect_to(root_path)

      expect(
        Investments::Transaction.exists?(other_transaction.id)
      ).to be(true)
    end
  end

end
