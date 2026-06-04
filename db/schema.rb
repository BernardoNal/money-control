# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_02_230054) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "bank"
    t.decimal "initial_balance"
    t.decimal "limit"
    t.string "last_digits"
    t.date "due_day"
    t.string "card_type"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.boolean "is_income"
    t.string "icon"
    t.string "color"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "investments_assets", force: :cascade do |t|
    t.string "name", null: false
    t.string "symbol", null: false
    t.integer "category", null: false
    t.string "currency", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "subcategory"
    t.index ["symbol"], name: "index_investments_assets_on_symbol", unique: true
  end

  create_table "investments_incomes", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "asset_id", null: false
    t.integer "income_type", null: false
    t.decimal "gross_amount", precision: 15, scale: 4, null: false
    t.decimal "net_amount", precision: 15, scale: 4, null: false
    t.decimal "tax_amount", precision: 15, scale: 4, default: "0.0", null: false
    t.date "payment_date", null: false
    t.date "reference_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_investments_incomes_on_asset_id"
    t.index ["payment_date"], name: "index_investments_incomes_on_payment_date"
    t.index ["portfolio_id"], name: "index_investments_incomes_on_portfolio_id"
  end

  create_table "investments_portfolios", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_investments_portfolios_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_investments_portfolios_on_user_id"
  end

  create_table "investments_transactions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "asset_id", null: false
    t.integer "transaction_type", null: false
    t.decimal "quantity", precision: 15, scale: 8, null: false
    t.decimal "price", precision: 15, scale: 4
    t.decimal "fees", precision: 15, scale: 4, default: "0.0", null: false
    t.date "date", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_investments_transactions_on_asset_id"
    t.index ["date"], name: "index_investments_transactions_on_date"
    t.index ["portfolio_id"], name: "index_investments_transactions_on_portfolio_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount"
    t.string "description"
    t.date "date"
    t.string "to_whom"
    t.string "payment_method"
    t.bigint "category_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "investments_incomes", "investments_assets", column: "asset_id"
  add_foreign_key "investments_incomes", "investments_portfolios", column: "portfolio_id"
  add_foreign_key "investments_portfolios", "users"
  add_foreign_key "investments_transactions", "investments_assets", column: "asset_id"
  add_foreign_key "investments_transactions", "investments_portfolios", column: "portfolio_id"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
end
