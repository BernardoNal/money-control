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
    # Mantemos uma categoria padrão por direção para que a ausência de escolha
    # não misture entradas e saídas nem impeça a conclusão da importação.
    name = income ? "Sem categoria (Entrada)" : "Sem categoria (Saída)"
    global.find_or_create_by!(name: name) do |category|
      category.is_income = income
      category.icon = "💳"
      category.color = "#64748b"
    end
  end

validates :icon, inclusion: { in: ICONS }

end
