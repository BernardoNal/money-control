class Category < ApplicationRecord
 belongs_to :user, optional: true
has_many :transactions, dependent: :nullify

validates :name, presence: true
validates :is_income, inclusion: { in: [true, false] }
validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "deve ser um código hexadecimal válido" }

# Categoria global se user_id for nil
scope :global, -> { where(user_id: nil) }
scope :for_user, ->(user_id) { where(user_id: user_id).or(global) }

ICONS = %w[💰 🛒 🍔 🚗 📈 🏠 🎓 💳]

  def self.uncategorized(income:)
    # Keep one default category per direction so an empty choice does not mix
    # income and expenses or prevent the import from being completed.
    name = income ? "Sem categoria (Entrada)" : "Sem categoria (Saída)"
    global.find_or_create_by!(name: name) do |category|
      category.is_income = income
      category.icon = "💳"
      category.color = "#64748b"
    end
  end

validates :icon, inclusion: { in: ICONS }

end
