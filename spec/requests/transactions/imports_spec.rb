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
  let(:csv) do
    <<~CSV
      Data,"Lançamento","Detalhes","N° documento","Valor","Tipo Lançamento"
      09/09/2026,"Pix - Recebido","Adrian","9175","110,00","Entrada"
      09/09/2026,"BB Rende Fácil","Rende Facil","9903","-110,00","Saída"
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
      row_categories: { "2" => category.id.to_s }
    }

    expect(response).to redirect_to(account_transaction_import_preview_path(account, import))
    expect(import.reload.rows.first["category_id"]).to eq(category.id)
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
end
