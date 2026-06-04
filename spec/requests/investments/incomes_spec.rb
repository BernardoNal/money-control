require "rails_helper"

RSpec.describe "Investments::Incomes", type: :request do
  let(:user) do
    User.create!(
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

  let(:asset) do
    Investments::Asset.create!(
      name: "MXRF11",
      symbol: "MXRF11",
      category: :fii,
      currency: "BRL"
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
  end
end
