module Investments
  class Asset < ApplicationRecord
    # Assets are modeled as a global market catalog, not as user-owned records.
    self.table_name = "investments_assets"

    CATEGORY_SUBCATEGORY_MAP = {
      "stock" => %w[banks energy technology retail mining agribusiness utilities healthcare],
      "fii" => %w[paper brick logistics shopping_malls offices receivables],
      "etf" => [],
      "crypto" => [],
      "fixed_income" => [],
      "international" => %w[technology retail energy mining utilities healthcare]
    }.freeze

    has_many :incomes, class_name: "Investments::Income", dependent: :restrict_with_exception
    has_many :transactions, class_name: "Investments::Transaction", dependent: :restrict_with_exception

    enum :category, {
      stock: 0,
      fii: 1,
      etf: 2,
      crypto: 3,
      fixed_income: 4,
      international: 5
    }

    enum :subcategory, {
      paper: 0,
      brick: 1,
      banks: 2,
      energy: 3,
      technology: 4,
      retail: 5,
      mining: 6,
      agribusiness: 7,
      logistics: 8,
      shopping_malls: 9,
      offices: 10,
      receivables: 11,
      utilities: 12,
      healthcare: 13
    }

    validates :name, :symbol, :category, :currency, presence: true
    validates :symbol, uniqueness: true
    validate :subcategory_must_match_category

    def self.allowed_subcategories_for(category)
      CATEGORY_SUBCATEGORY_MAP.fetch(category.to_s, [])
    end

    def self.category_supports_subcategories?(category)
      allowed_subcategories_for(category).any?
    end

    def human_category
      I18n.t(
        "activerecord.attributes.investments/asset.categories.#{category}"
      )
    end

    def human_subcategory
      return "-" if subcategory.blank?

      I18n.t(
        "activerecord.attributes.investments/asset.subcategories.#{subcategory}"
      )
    end

    private

    def subcategory_must_match_category
      return if subcategory.blank? || category.blank?

      return if self.class.allowed_subcategories_for(category).include?(subcategory)

      errors.add(:subcategory, :invalid_for_category)
    end
  end
end
