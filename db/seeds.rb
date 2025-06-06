puts "Limpando dados..."
Transaction.delete_all
Category.delete_all
Account.delete_all
User.delete_all

puts "Criando usuário..."
user = User.create!(
  name: "Usuário Teste",
  email: "teste@moneycontrol.com",
  password: "123456",
  password_confirmation: "123456"
)

puts "Criando categorias globais..."
global_categories = [
  { name: "Salário", is_income: true, icon: "💰", color: "#00cc66" },
  { name: "Aluguel", is_income: false, icon: "🏠", color: "#ff6666" },
  { name: "Alimentação", is_income: false, icon: "🍴", color: "#3366ff" },
  { name: "Água", is_income: true, icon: "🚿", color: "#1F5BC5" },
  { name: "Investimentos", is_income: true, icon: "📈", color: "#ffaa00" }
]

global_categories.each do |cat|
  Category.create!(cat)
end

p user
puts "Criando categorias específicas do usuário..."
user_categories = [
  { name: "Mercado", is_income: false, icon: "🛒", color: "#ff9933", user_id: user.id },
  { name: "Transporte", is_income: false, icon: "🚗", color: "#9999ff", user_id: user.id }
]

user_categories.each do |cat|
  Category.create!(cat)
end

puts "Criando contas..."
account1 = Account.create!(
  name: "Conta Corrente",
  bank: "Nubank",
  initial_balance: 1500.00,
  user_id: user.id
)

account2 = Account.create!(
  name: "Cartão Nubank",
  bank: "Nubank",
  initial_balance: 0.00,
  limit: 2000,
  last_digits: "1234",
  due_day: Date.today + 20,
  card_type: "credit",
  user_id: user.id
)

puts "Criando transações..."

Transaction.create!(
  amount: 500.00,
  description: "Salário de junho",
  date: Date.today - 5,
  to_whom: "Empresa XYZ",
  payment_method: "TED",
  category: Category.find_by(name: "Salário"),
  account: account1
)

Transaction.create!(
  amount: 120.50,
  description: "Supermercado",
  date: Date.today - 2,
  to_whom: "Supermercado do Bairro",
  payment_method: "Débito",
  category: Category.find_by(name: "Mercado", user_id: user.id),
  account: account1
)

Transaction.create!(
  amount: 300.00,
  description: "Conta de água",
  date: Date.today - 1,
  to_whom: "Igua",
  payment_method: "Cartão de Crédito",
  category: Category.find_by(name: "Água"),
  account: account2
)

puts "Seeds finalizados com sucesso!"
