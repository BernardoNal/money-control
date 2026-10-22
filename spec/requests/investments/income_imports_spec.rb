require "rails_helper"

RSpec.describe "Investments::IncomeImports", type: :request do
  let(:user) do
    User.create!(name: "Income Import User", email: "income-import@example.com", password: "password123")
  end

  let!(:portfolio) do
    Investments::Portfolio.create!(name: "Carteira principal", user: user)
  end

  before { sign_in user }

  def xlsx
    rows = [
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "DIVIDENDOS DE CLIENTES COCA34 S/ 5", "1,51"],
      [46310, 46310, "CREDITO DE REEMBOLSO DE EVENTO BRXPLGCTF002", "0,82"]
    ]
    worksheet = rows.each_with_index.map do |values, row_index|
      cells = values.each_with_index.map do |value, column_index|
        column = ("A".ord + column_index).chr
        if value.is_a?(Numeric)
          "<c r=\"#{column}#{row_index + 1}\"><v>#{value}</v></c>"
        else
          "<c r=\"#{column}#{row_index + 1}\" t=\"inlineStr\"><is><t>#{CGI.escapeHTML(value)}</t></is></c>"
        end
      end.join
      "<row r=\"#{row_index + 1}\">#{cells}</row>"
    end.join
    xml = "<?xml version=\"1.0\"?><worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>#{worksheet}</sheetData></worksheet>"

    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("xl/worksheets/sheet1.xml")
      zip.write(xml)
    end

    buffer.string
  end

  def upload
    tempfile = Tempfile.new(["income", ".xlsx"])
    tempfile.binmode
    tempfile.write(xlsx)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", false)
  end

  it "renders the upload page for the selected portfolio" do
    get investments_portfolio_income_import_path(portfolio)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Carregar XLSX em Carteira principal")
  end

  it "persists an account-scoped preview without creating incomes" do
    file = upload

    expect do
      post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    end.to change(Investments::IncomeImport, :count).by(1)
      .and change(Investments::Income, :count).by(0)

    income_import = Investments::IncomeImport.last
    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(income_import.portfolio).to eq(portfolio)
    expect(income_import.rows.first["classification"]).to eq("dividends")
    expect(income_import.rows.second["requires_review"]).to be(true)
  ensure
    file&.tempfile&.close!
  end

  it "rejects a missing file without creating a preview" do
    expect do
      post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: nil } }
    end.not_to change(Investments::IncomeImport, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Selecione um arquivo XLSX")
  end

  it "does not expose another user's portfolio" do
    other_user = User.create!(name: "Other", email: "other-income-import@example.com", password: "password123")
    other_portfolio = Investments::Portfolio.create!(name: "Outra", user: other_user)

    get investments_portfolio_income_import_path(other_portfolio)

    expect(response).to redirect_to(root_path)
  end
end
