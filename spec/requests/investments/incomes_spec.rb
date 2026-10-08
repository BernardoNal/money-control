require "rails_helper"

RSpec.describe "Investments::Incomes", type: :request do
  let(:user) do
    User.create!(
      name: "Income User",
      email: "user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      name: "Carteira Principal",
      user: user
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other Income User",
      email: "other-user@example.com",
      password: "password123"
    )
  end

  let(:other_portfolio) do
    Investments::Portfolio.create!(
      name: "Outra Carteira",
      user: other_user
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "MXRF11",
      symbol: "MXRF11",
      category: :fii,
      currency: "BRL"
    )
  end

  let(:other_income) do
    Investments::Income.create!(
      portfolio: other_portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 10,
      net_amount: 10,
      tax_amount: 0,
      payment_date: Date.current
    )
  end

  before do
    sign_in user
  end

  describe "GET /index" do
    it "returns success" do
      get investments_incomes_path

      expect(response).to have_http_status(:ok)
    end

    it "renders overview analytics for the current user's incomes" do
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 120,
        tax_amount: 20,
        payment_date: Date.current
      )
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :jcp,
        gross_amount: 50,
        tax_amount: 5,
        payment_date: Date.current
      )

      get investments_incomes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visão geral")
      expect(response.body).to include("Total recebido no período")
      expect(response.body).to include("R$ 145,00")
      expect(response.body).to include("Média por provento")
      expect(response.body).to include("R$ 72,50")
      expect(response.body).to include("Maior provento")
      expect(response.body).to include("R$ 100,00")
      expect(response.body).to include("MXRF11")
      expect(response.body).to include("Dividendos")
      expect(response.body).to include("Últimos 30 dias")
      expect(response.body).to include("Últimos 3 proventos")
      expect(response.body).to include("Distribuição por tipo")
    end

    it "switches the overview metrics to the last 30 days" do
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 120,
        tax_amount: 20,
        payment_date: 10.days.ago.to_date
      )
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :jcp,
        gross_amount: 50,
        tax_amount: 5,
        payment_date: 60.days.ago.to_date
      )

      get investments_incomes_path, params: { income_period: "30d" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("R$ 100,00")
      expect(response.body).not_to include("R$ 145,00")
      expect(response.body).to include("income_period=30d")
    end

    it "supports an all-time overview period" do
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 75,
        tax_amount: 0,
        payment_date: 2.years.ago.to_date
      )

      get investments_incomes_path, params: { income_period: "all" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Todo o período")
      expect(response.body).to include("R$ 75,00")
      expect(response.body).to include("income_period=all")
    end

    it "keeps the existing income list under the list tab" do
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 25,
        tax_amount: 0,
        payment_date: Date.current
      )

      get investments_incomes_path, params: { tab: "list", income_type: "dividends" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Valor Líquido")
      expect(response.body).to include("MXRF11")
      expect(response.body).to include("Lista")
      expect(response.body).to include('name="tab"')
      expect(response.body).to include('value="list"')
    end
  end

  describe "GET /show" do
    it "returns success" do
      income = Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 10,
        net_amount: 10,
        tax_amount: 0,
        payment_date: Date.current
      )

      get investments_income_path(income)

      expect(response).to have_http_status(:ok)
    end

     it "does not expose another user's income" do
      get investments_income_path(other_income)

      expect(response).to redirect_to(root_path)
    end

    it "redirects with a friendly alert when the income does not exist" do
      get investments_income_path(999_999)

      expect(response).to redirect_to(investments_incomes_path)
      expect(flash[:alert]).to eq("Registro não encontrado ou indisponivel.")
    end
  end

  describe "POST /create" do
    it "creates an income" do
      expect do
        post investments_incomes_path, params: {
          investments_income: {
            portfolio_id: portfolio.id,
            asset_id: asset.id,
            income_type: "dividends",
            gross_amount: 10,
            net_amount: 10,
            tax_amount: 0,
            payment_date: Date.current
          }
        }
      end.to change(Investments::Income, :count).by(1)

      expect(response).to redirect_to(
        investments_income_path(Investments::Income.last)
      )
    end

    it "does not allow creating an income in another user's portfolio" do
      expect do
        post investments_incomes_path, params: {
          investments_income: {
            portfolio_id: other_portfolio.id,
            asset_id: asset.id,
            income_type: "dividends",
            gross_amount: 10,
            tax_amount: 0,
            payment_date: Date.current
          }
        }
      end.not_to change(Investments::Income, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /update" do
    it "updates an income" do
      income = Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 10,
        net_amount: 10,
        tax_amount: 0,
        payment_date: Date.current
      )

      patch investments_income_path(income), params: {
        investments_income: {
          gross_amount: 25
        }
      }

      expect(income.reload.gross_amount).to eq(25)
    end

    it "allows reassigning an income to another portfolio owned by the current user" do
      destination_portfolio = Investments::Portfolio.create!(
        user: user,
        name: "Reserve Portfolio"
      )
      income = Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 10,
        net_amount: 10,
        tax_amount: 0,
        payment_date: Date.current
      )

      patch investments_income_path(income), params: {
        investments_income: { portfolio_id: destination_portfolio.id }
      }

      expect(response).to redirect_to(investments_income_path(income))
      expect(income.reload.portfolio).to eq(destination_portfolio)
    end

    it "does not allow reassigning an income to another users portfolio" do
      income = Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 10,
        net_amount: 10,
        tax_amount: 0,
        payment_date: Date.current
      )

      patch investments_income_path(income), params: {
        investments_income: { portfolio_id: other_portfolio.id }
      }

      expect(response).to redirect_to(root_path)
      expect(income.reload.portfolio).to eq(portfolio)
    end

    it "does not allow updating another user's income" do
      patch investments_income_path(other_income), params: {
        investments_income: {
          gross_amount: 999
        }
      }

      expect(response).to redirect_to(root_path)

      other_income.reload
      expect(other_income.gross_amount).to eq(10)
    end
  end

  describe "DELETE /destroy" do
    it "deletes an income" do
      income = Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: 10,
        net_amount: 10,
        tax_amount: 0,
        payment_date: Date.current
      )

      expect do
        delete investments_income_path(income)
      end.to change(Investments::Income, :count).by(-1)
    end

    it "does not allow destroying another user's income" do
      other_income

      expect do
        delete investments_income_path(other_income)
      end.not_to change(Investments::Income, :count)

      expect(response).to redirect_to(root_path)
      expect(Investments::Income.exists?(other_income.id)).to be(true)
    end
  end
end
