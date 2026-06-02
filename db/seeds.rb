puts "Limpando dados..."
Investments::Income.delete_all
Investments::Transaction.delete_all
Investments::Asset.delete_all
Investments::Portfolio.delete_all
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
  { name: "Alimentação", is_income: false, icon: "🍔", color: "#3366ff" },
  { name: "Água", is_income: true, icon: "💳", color: "#1F5BC5" },
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

puts "Criando portfolio de investimentos..."
portfolio = Investments::Portfolio.create!(
  name: "Portfolio Principal",
  user: user
)

puts "Criando ativos de investimentos..."
apple = Investments::Asset.create!(
  name: "Apple Inc.",
  symbol: "AAPL",
  category: :international,
  currency: "USD"
)

xpml = Investments::Asset.create!(
  name: "XP Malls",
  symbol: "XPML11",
  category: :fii,
  currency: "BRL"
)

btc = Investments::Asset.create!(
  name: "Bitcoin",
  symbol: "BTC",
  category: :crypto,
  currency: "USD"
)

puts "Criando transações de investimentos..."
Investments::Transaction.create!(
  portfolio: portfolio,
  asset: apple,
  transaction_type: :buy,
  quantity: 10,
  price: 20,
  fees: 5,
  date: Date.today - 25,
  notes: "Primeira compra"
)

Investments::Transaction.create!(
  portfolio: portfolio,
  asset: apple,
  transaction_type: :buy,
  quantity: 5,
  price: 30,
  fees: 10,
  date: Date.today - 18,
  notes: "Reforço de posição"
)

Investments::Transaction.create!(
  portfolio: portfolio,
  asset: apple,
  transaction_type: :sell,
  quantity: 5,
  price: 42,
  fees: 0,
  date: Date.today - 10,
  notes: "Realização parcial"
)

Investments::Transaction.create!(
  portfolio: portfolio,
  asset: xpml,
  transaction_type: :buy,
  quantity: 20,
  price: 10,
  fees: 0,
  date: Date.today - 15,
  notes: "Entrada em FII"
)

Investments::Transaction.create!(
  portfolio: portfolio,
  asset: btc,
  transaction_type: :buy,
  quantity: 0.25,
  price: 250000,
  fees: 50,
  date: Date.today - 12,
  notes: "Compra inicial de BTC"
)

puts "Criando rendimentos de investimentos..."
Investments::Income.create!(
  portfolio: portfolio,
  asset: xpml,
  income_type: :fii_income,
  gross_amount: 24,
  net_amount: 24,
  tax_amount: 0,
  payment_date: Date.today - 3,
  reference_date: Date.today - 8,
  notes: "Rendimento mensal do FII"
)

Investments::Income.create!(
  portfolio: portfolio,
  asset: apple,
  income_type: :dividends,
  gross_amount: 18,
  net_amount: 15.3,
  tax_amount: 2.7,
  payment_date: Date.today - 6,
  reference_date: Date.today - 14,
  notes: "Dividendos trimestrais"
)

puts "Dados de investimentos criados para visualizar o dashboard."
puts "Seeds finalizados com sucesso!"
