require "rails_helper"

RSpec.describe "Transactions::Imports", type: :request do
  let(:user) do
    User.create!(name: "Import User", email: "import@example.com", password: "password123")
  end
  let!(:account) do
    Account.create!(user: user, name: "Conta principal", bank: "Banco do Brasil", initial_balance: 0)
  end
  let!(:category) do
    Category.create!(
      user: user,
      name: "Despesas",
      is_income: false,
      color: "#2563eb",
      icon: "💳"
    )
  end
  let!(:income_category) do
    Category.create!(
      user: user,
      name: "Receitas",
      is_income: true,
      icon: "💰",
      color: "#16a34a"
    )
  end
  let(:csv) do
    <<~CSV
      Data,"Lançamento","Detalhes","N° documento","Valor","Tipo Lançamento"
      09/09/2026,"Pix - Recebido","Adrian","9175","110,00","Entrada"
      09/09/2026,"BB Rende Fácil","Rende Facil","9903","-110,00","Saída"
    CSV
  end
  let(:identified_csv) do
    <<~CSV
      Data,Valor,Descrição,Identificador
      09/09/2026,110.00,Pix recebido,abc-123
    CSV
  end

  before { sign_in user }

  it "renders the upload page for the selected account" do
    get account_transaction_import_path(account)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Conta principal")
  end

  it "creates an account-scoped preview without creating transactions" do
    tempfile = Tempfile.new(["statement", ".csv"])
    tempfile.write(csv)
    tempfile.rewind
    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false)

    expect do
      post account_transaction_import_create_path(account), params: { transaction_import: { file: upload } }, as: :multipart
    end.to change(TransactionImport, :count).by(1).and change(Transaction, :count).by(0)

    import = TransactionImport.last
    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(import.account).to eq(account)
    expect(import.rows.first["description"]).to eq("Pix - Recebido")
    expect(import.rows.second["status"]).to eq("ignored")
    get account_transaction_import_preview_path(account, import)
    expect(response.body).to include("Válida")
  ensure
    tempfile&.close!
  end

  it "stores category selections only on the preview draft" do
    import = TransactionImport.create!(
      account: account,
      original_filename: "statement.csv",
      rows: [{ "line_number" => 2, "status" => "valid", "description" => "Compra" }],
      summary: { "valid" => 1 }
    )

    patch account_transaction_import_update_path(account, import), params: {
      row_categories: { "2" => income_category.id.to_s }
    }

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(import.reload.rows.first["category_id"]).to eq(income_category.id)
    expect(Transaction.count).to eq(0)
  end

  it "does not allow access to an account owned by another user" do
    other_user = User.create!(name: "Other", email: "other-import@example.com", password: "password123")
    other_account = Account.create!(user: other_user, name: "Outra", bank: "Inter", initial_balance: 0)

    get account_transaction_import_path(other_account)

    expect(response).to redirect_to(root_path)
  end

  it "rejects a missing file without creating a draft" do
    expect do
      post account_transaction_import_create_path(account), params: { transaction_import: { file: nil } }
    end.not_to change(TransactionImport, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Selecione um arquivo CSV")
  end

  it "confirms categorized rows atomically and marks the draft completed" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Pix recebido",
        "category_id" => income_category.id,
        "status" => "valid"
      }
    )

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.to change(Transaction, :count).by(1)

    expect(response).to redirect_to(account_path(account))
    expect(import.reload.status).to eq("completed")
    expect(Transaction.last.category).to eq(income_category)
  end

  it "uses the global uncategorized category when no category is selected" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Pix recebido",
        "category_id" => nil,
        "status" => "valid"
      }
    )

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.to change(Transaction, :count).by(1)

    expect(response).to redirect_to(account_path(account))
    expect(import.reload.status).to eq("completed")
    expect(Transaction.last.category.name).to eq("Sem categoria (Entrada)")
  end

  it "does not replay a completed import" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Pix recebido",
        "category_id" => income_category.id,
        "status" => "valid"
      }
    )
    post account_transaction_import_confirm_path(account, import)

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.not_to change(Transaction, :count)

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(flash[:alert]).to include("já foi confirmada")
  end

  it "rolls back every transaction when one row fails" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Primeira linha",
        "category_id" => income_category.id,
        "status" => "valid"
      },
      {
        "line_number" => 3,
        "date" => "2026-09-09",
        "amount" => nil,
        "description" => "Linha inválida",
        "category_id" => income_category.id,
        "status" => "valid"
      }
    )

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.not_to change(Transaction, :count)

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(import.reload.status).to eq("pending")
  end

  it "rejects a category owned by another user" do
    other_user = User.create!(name: "Other", email: "category-owner@example.com", password: "password123")
    other_category = Category.create!(
      user: other_user,
      name: "Privada",
      is_income: false,
      color: "#dc2626",
      icon: "💳"
    )
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Pix recebido",
        "category_id" => other_category.id,
        "status" => "valid"
      }
    )

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.not_to change(Transaction, :count)

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(flash[:alert]).to include("não pertencem")
  end

  it "expires a draft before creating transactions" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "date" => "2026-09-09",
        "amount" => "110.0",
        "description" => "Pix recebido",
        "category_id" => income_category.id,
        "status" => "valid"
      }
    )
    import.update!(expires_at: 1.minute.ago)

    expect do
      post account_transaction_import_confirm_path(account, import)
    end.not_to change(Transaction, :count)

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(flash[:alert]).to be_blank
    expect(import.reload.status).to eq("expired")

    get account_transaction_import_preview_path(account, import)
    expect(response.body).to include("Esta importação expirou. Envie o arquivo novamente para iniciar uma nova revisão.")
    expect(response.body).not_to include("Esta importação expirou. Envie o arquivo novamente.")
    expect(response.body).not_to include("Esta importação já foi concluída.")
  end

  it "lists pending imports on the account and cancels without deleting them" do
    import = draft_with_rows(
      {
        "line_number" => 2,
        "status" => "ignored",
        "ignored_reason" => "Saldo bancário."
      }
    )

    get account_path(account)
    expect(response.body).to include("statement.csv", "Retomar", "Cancelar")

    delete account_transaction_import_cancel_path(account, import)

    expect(response).to redirect_to(account_path(account))
    expect(import.reload.status).to eq("cancelled")
    expect(TransactionImport.exists?(import.id)).to be(true)
  end

  it "marks a repeated imported row as a possible duplicate" do
    post_csv_import
    first_import = TransactionImport.last
    patch account_transaction_import_update_path(account, first_import), params: {
      row_categories: { "2" => income_category.id.to_s },
      selected_lines: ["2"]
    }
    post account_transaction_import_confirm_path(account, first_import)

    post_csv_import
    second_import = TransactionImport.last

    expect(second_import.rows.first["possible_duplicate"]).to be(true)
    expect(second_import.rows.first["duplicate_type"]).to eq("possible")
    expect(second_import.rows.first["selected"]).to be(false)
    expect(second_import.summary["possible_duplicate"]).to eq(1)
  end

  it "matches a previous transaction without import metadata" do
    Transaction.create!(
      account: account,
      category: income_category,
      amount: 110,
      date: Date.new(2026, 9, 9),
      description: "Pix - Recebido",
      to_whom: "Adrian",
      source_document_number: "9175"
    )

    post_csv_import

    row = TransactionImport.last.rows.first
    expect(row["possible_duplicate"]).to be(true)
    expect(row["duplicate_type"]).to eq("possible")
    expect(row["selected"]).to be(false)
  end

  it "falls back to transaction attributes when an older import has no source identifier" do
    Transaction.create!(
      account: account,
      category: income_category,
      amount: 110,
      date: Date.new(2026, 9, 9),
      description: "Pix recebido"
    )

    post_csv_import(identified_csv)

    row = TransactionImport.last.rows.first
    expect(row["duplicate_type"]).to eq("possible")
    expect(row["selected"]).to be(false)
  end

  it "marks a repeated stable source identifier as a confirmed duplicate" do
    post_csv_import(identified_csv)
    first_import = TransactionImport.last
    patch account_transaction_import_update_path(account, first_import), params: {
      row_categories: { "2" => income_category.id.to_s },
      selected_lines: ["2"]
    }
    post account_transaction_import_confirm_path(account, first_import)

    post_csv_import(identified_csv)
    second_import = TransactionImport.last

    expect(second_import.rows.first["confirmed_duplicate"]).to be(true)
    expect(second_import.rows.first["possible_duplicate"]).to be(false)
    expect(second_import.rows.first["duplicate_type"]).to eq("confirmed")
    expect(second_import.rows.first["selected"]).to be(false)
    expect(second_import.summary["confirmed_duplicate"]).to eq(1)
  end

  it "marks repeated stable identifiers within one import as confirmed duplicates" do
    post_csv_import(<<~CSV)
      Data,Valor,Descrição,Identificador
      09/09/2026,110.00,Pix recebido,abc-123
      09/09/2026,110.00,Pix recebido,abc-123
    CSV

    import = TransactionImport.last

    expect(import.rows.map { |row| row["duplicate_type"] }).to eq([nil, "confirmed"])
    expect(import.rows.second["duplicate_reason"]).to include("linha 2")
  end

  it "does not match a stable identifier from another account" do
    other_account = Account.create!(user: user, name: "Outra conta", bank: "Outro banco", initial_balance: 0)
    Transaction.create!(
      account: other_account,
      category: income_category,
      amount: 110,
      date: Date.new(2026, 9, 9),
      description: "Pix recebido",
      source_identifier: "abc-123"
    )

    post_csv_import(identified_csv)

    row = TransactionImport.last.rows.first
    expect(row["duplicate_type"]).to be_nil
    expect(row["selected"]).to be(true)
  end

  it "allows a user to reselect a possible duplicate explicitly" do
    post_csv_import
    first_import = TransactionImport.last
    patch account_transaction_import_update_path(account, first_import), params: {
      row_categories: { "2" => income_category.id.to_s },
      selected_lines: ["2"]
    }
    post account_transaction_import_confirm_path(account, first_import)

    post_csv_import
    second_import = TransactionImport.last
    patch account_transaction_import_update_path(account, second_import), params: {
      row_categories: { "2" => income_category.id.to_s },
      selected_lines: ["2"]
    }

    expect do
      post account_transaction_import_confirm_path(account, second_import)
    end.to change(Transaction, :count).by(1)
  end

  it "keeps the original description by default and allows editing it" do
    post_csv_import
    import = TransactionImport.last

    patch account_transaction_import_update_path(account, import), params: {
      row_categories: { "2" => income_category.id.to_s },
      selected_lines: ["2"],
      row_descriptions: { "2" => "Recebimento do Adrian" }
    }
    post account_transaction_import_confirm_path(account, import)

    expect(Transaction.last.description).to eq("Recebimento do Adrian")
  end

  it "applies review changes when confirming directly" do
    post_csv_import
    import = TransactionImport.last

    expect do
      post account_transaction_import_confirm_path(account, import), params: {
        row_categories: { "2" => income_category.id.to_s },
        selected_lines: ["2"],
        row_descriptions: { "2" => "Recebimento confirmado" }
      }
    end.to change(Transaction, :count).by(1)

    expect(Transaction.last.description).to eq("Recebimento confirmado")
  end

  private

  def draft_with_rows(*rows)
    TransactionImport.create!(
      account: account,
      original_filename: "statement.csv",
      rows: rows,
      summary: { "valid" => rows.size },
      expires_at: 1.hour.from_now
    )
  end

  def post_csv_import(csv_content = csv)
    tempfile = Tempfile.new(["statement", ".csv"])
    tempfile.write(csv_content)
    tempfile.rewind
    upload = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false)
    post account_transaction_import_create_path(account), params: { transaction_import: { file: upload } }, as: :multipart
  ensure
    tempfile&.close!
  end
end
