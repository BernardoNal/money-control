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

  describe "authorization" do
    it "does not expose another user's portfolio" do
      get investments_portfolio_path(other_portfolio)

      expect(response).to redirect_to(investments_portfolios_path)
      expect(flash[:alert]).to eq("Registro nao encontrado ou indisponivel.")
    end
  end
  describe "GET /new" do
    it "redirects to the index with the new portfolio modal open" do
      get new_investments_portfolio_path

      expect(response).to redirect_to(investments_portfolios_path(modal: "new"))
    end
  end

  describe "GET /index" do
    it "lists only portfolios from the current user" do

      get investments_portfolios_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Portfolio")
      expect(response.body).not_to include("Other Portfolio")
    end

    it "renders the modal when requested through params" do
      get investments_portfolios_path, params: { modal: "new" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Novo portfolio")
      expect(response.body).to include("Criar portfolio")
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
      expect(response.body).to include("Investimentos")
      expect(response.body).to include("Main Portfolio")
      expect(response.body).to include("Visao geral")
      expect(response.body).to include("Carteira")
      expect(response.body).to include("Total investido")
      expect(response.body).to include("Evolucao historica")
      expect(response.body).to include("Renda passiva liquida")
      expect(response.body).to include("Alocacao por categoria")
      expect(response.body).to include("Alocacao por subcategoria")
      expect(response.body).to include("Preco atual")
      expect(response.body).to include("Valor atual da carteira")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Internacional")
      expect(response.body).to include("Ações")
      expect(response.body).to include("Tecnologia")
      expect(response.body).to include("Bancos")
      expect(response.body).to include("Sem subcategoria")
    end

    it "filters dashboard data by category and preserves selected filters" do
      get investments_portfolio_path(portfolio), params: { category: "stock" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Banco do Brasil")
      expect(response.body).not_to include("Apple Inc.")
      expect(response.body).to include('option selected="selected" value="stock"')
    end

    it "filters dashboard data by date range and preserves date fields" do
      older_only_asset = Investments::Asset.create!(
        name: "Old Position",
        symbol: "OLD1",
        category: :stock,
        currency: "BRL"
      )

      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: older_only_asset,
        transaction_type: :buy,
        quantity: 3,
        price: 12,
        fees: 0,
        date: Date.new(2026, 1, 10)
      )

      get investments_portfolio_path(portfolio), params: {
        from_date: Date.current.to_s,
        to_date: Date.current.to_s
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Old Position")
      expect(response.body).to include(%(value="#{Date.current}"))
    end

    it "applies the selected preset period to the dashboard filters" do
      older_only_asset = Investments::Asset.create!(
        name: "Old Position",
        symbol: "OLD1",
        category: :stock,
        currency: "BRL"
      )

      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: older_only_asset,
        transaction_type: :buy,
        quantity: 3,
        price: 12,
        fees: 0,
        date: Date.current - 2.months
      )

      get investments_portfolio_path(portfolio), params: { period: "30d" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Old Position")
      expect(response.body).to include('option selected="selected" value="30d"')
    end

    it "uses tempo todo as the default preset" do
      get investments_portfolio_path(portfolio)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('option selected="selected" value="all"')
    end

    it "redirects with a friendly alert for a portfolio from another user" do
      other_user = User.create!(
        name: "Another User",
        email: "another-user@example.com",
        password: "password123"
      )
      other_portfolio = Investments::Portfolio.create!(user: other_user, name: "Private Portfolio")

      get investments_portfolio_path(other_portfolio)

      expect(response).to redirect_to(investments_portfolios_path)
      expect(flash[:alert]).to eq("Registro nao encontrado ou indisponivel.")
    end

    it "redirects with a friendly alert when the portfolio does not exist" do
      get investments_portfolio_path(id: 999_999)

      expect(response).to redirect_to(investments_portfolios_path)
      expect(flash[:alert]).to eq("Registro nao encontrado ou indisponivel.")
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

    it "re-renders the index modal when validation fails" do
      post investments_portfolios_path, params: {
        investments_portfolio: {
          name: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Novo portfolio")
      expect(response.body).to include("Nao foi possivel salvar o portfolio")
    end
  end

  describe "PATCH /update" do
    it "redirects edit to the index modal" do
      get edit_investments_portfolio_path(portfolio)

      expect(response).to redirect_to(investments_portfolios_path(modal: "edit", portfolio_id: portfolio.id))
    end

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

    it "re-renders the edit modal when validation fails" do
      patch investments_portfolio_path(portfolio), params: {
        investments_portfolio: {
          name: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Editar portfolio")
      expect(response.body).to include("Nao foi possivel salvar o portfolio")
    end

    it "redirects with a friendly alert for a portfolio from another user" do
      other_portfolio = Investments::Portfolio.create!(user: other_user, name: "Private Portfolio")

      patch investments_portfolio_path(other_portfolio), params: {
        investments_portfolio: {
          name: "Attempted Update"
        }
      }

      expect(response).to redirect_to(investments_portfolios_path)
      expect(flash[:alert]).to eq("Registro nao encontrado ou indisponivel.")
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
