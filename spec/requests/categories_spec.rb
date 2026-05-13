require 'rails_helper'

RSpec.describe "Categories", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "categories@example.com",
      password: "password123"
    )
  end

  let!(:category) do
    Category.create!(
      user: user,
      name: "Alimentacao",
      is_income: false,
      icon: "🍔",
      color: "#ff6600"
    )
  end

  before do
    sign_in user
  end

  describe "PATCH /update" do
    it "updates the existing category without creating a new record" do
      expect do
        patch category_path(category), params: {
          category: {
            name: "Mercado",
            is_income: true,
            icon: "💰",
            color: "#00aa00"
          }
        }
      end.not_to change(Category, :count)

      expect(response).to redirect_to(category_path(category))

      category.reload
      expect(category.name).to eq("Mercado")
      expect(category.is_income).to be(true)
      expect(category.icon).to eq("💰")
      expect(category.color).to eq("#00aa00")
    end

    it "renders form when the update is invalid" do
      patch category_path(category), params: {
        category: {
          name: "",
          color: "invalid-color"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)

      category.reload
      expect(category.name).to eq("Alimentacao")
      expect(category.color).to eq("#ff6600")
    end
  end

  describe "DELETE /destroy" do
    it "removes the category and redirects to categories index" do
      expect do
        delete category_path(category)
      end.to change(Category, :count).by(-1)

      expect(response).to redirect_to(categories_path)
    end
  end
end
