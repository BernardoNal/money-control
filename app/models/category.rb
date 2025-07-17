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


validates :icon, inclusion: { in: ICONS }

end
