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
