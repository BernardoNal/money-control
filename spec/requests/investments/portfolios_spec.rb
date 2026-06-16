require "rails_helper"

RSpec.describe "Investments::Portfolios", type: :request do
  let(:user) do
    User.create!(
      name: "Portfolio User",
      email: "portfolio-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other User",
      email: "other-portfolio-user@example.com",
      password: "password123"
    )
  end

  let!(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Main Portfolio"
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

  let!(:stock_asset) do
    Investments::Asset.create!(
      name: "Banco do Brasil",
      symbol: "BBAS3",
      category: :stock,
      subcategory: :banks,
      currency: "BRL"
    )
  end

  let!(:fixed_income_asset) do
    Investments::Asset.create!(
      name: "Tesouro Selic",
      symbol: "SELIC2029",
      category: :fixed_income,
      currency: "BRL"
    )
  end

  before do
    sign_in user
  end

  describe "GET /new" do
    it "renders the new portfolio form successfully" do
      get new_investments_portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Novo Portfolio")
    end
  end

  describe "GET /index" do
    it "lists only portfolios from the current user" do
      other_portfolio = Investments::Portfolio.create!(user: other_user, name: "Other Portfolio")

      get investments_portfolios_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Portfolio")
      expect(response.body).not_to include(other_portfolio.name)
    end
  end

  describe "GET /show" do
    before do
      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: asset,
        transaction_type: :buy,
        quantity: 2,
        price: 10,
        fees: 0,
        date: Date.current
      )

      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 5,
        net_amount: 5,
        tax_amount: 0,
        payment_date: Date.current
      )

      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: stock_asset,
        transaction_type: :buy,
        quantity: 1,
        price: 30,
        fees: 0,
        date: Date.current
      )

      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: fixed_income_asset,
        transaction_type: :buy,
        quantity: 1,
        price: 15,
        fees: 0,
        date: Date.current
      )
    end

    it "renders the initial dashboard metrics for the portfolio" do
      get investments_portfolio_path(portfolio)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Portfolio Dashboard")
      expect(response.body).to include("Total investido")
      expect(response.body).to include("Renda passiva liquida")
      expect(response.body).to include("Alocacao por categoria")
      expect(response.body).to include("Alocacao por subcategoria")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Internacional")
      expect(response.body).to include("Ações")
      expect(response.body).to include("Tecnologia")
      expect(response.body).to include("Bancos")
      expect(response.body).to include("Sem subcategoria")
    end

    it "returns not found for a portfolio from another user" do
      other_user = User.create!(
        name: "Another User",
        email: "another-user@example.com",
        password: "password123"
      )
      other_portfolio = Investments::Portfolio.create!(user: other_user, name: "Private Portfolio")

      get investments_portfolio_path(other_portfolio)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /create" do
    it "creates a portfolio for the current user" do
      expect do
        post investments_portfolios_path, params: {
          investments_portfolio: {
            name: "Crypto Portfolio"
          }
        }
      end.to change(Investments::Portfolio, :count).by(1)

      expect(response).to redirect_to(investments_portfolio_path(Investments::Portfolio.last))
      expect(Investments::Portfolio.last.user).to eq(user)
    end
  end

  describe "PATCH /update" do
    it "updates the existing portfolio without creating a new record" do
      expect do
        patch investments_portfolio_path(portfolio), params: {
          investments_portfolio: {
            name: "International Portfolio"
          }
        }
      end.not_to change(Investments::Portfolio, :count)

      expect(response).to redirect_to(investments_portfolio_path(portfolio))

      portfolio.reload
      expect(portfolio.name).to eq("International Portfolio")
    end

    it "returns not found for a portfolio from another user" do
      other_portfolio = Investments::Portfolio.create!(user: other_user, name: "Private Portfolio")

      patch investments_portfolio_path(other_portfolio), params: {
        investments_portfolio: {
          name: "Attempted Update"
        }
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /destroy" do
    it "removes the portfolio and redirects to index" do
      expect do
        delete investments_portfolio_path(portfolio)
      end.to change(Investments::Portfolio, :count).by(-1)

      expect(response).to redirect_to(investments_portfolios_path)
    end
  end
end
