require "rails_helper"

RSpec.describe "Investments::IncomeImports", type: :request do
  let(:user) do
    User.create!(name: "Income Import User", email: "income-import@example.com", password: "password123")
  end

  let!(:portfolio) do
    Investments::Portfolio.create!(name: "Carteira principal", user: user)
  end

  let!(:asset) do
    Investments::Asset.create!(name: "Coca-Cola", symbol: "COCA34", category: :international, currency: "BRL")
  end

  let!(:suggested_asset) do
    Investments::Asset.create!(name: "B3 S.A.", symbol: "B3SA3", category: :stock, currency: "BRL")
  end

  before { sign_in user }

  def xlsx
    rows = [
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "DIVIDENDOS DE CLIENTES COCA34 S/ 5", "1,51"],
      [46310, 46310, "CREDITO DE REEMBOLSO DE EVENTO BRB3SAACNOR6", "0,82"]
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

  it "renders a matching corporate-event asset as a manual suggestion" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    get investments_portfolio_income_import_preview_path(portfolio, income_import)

    expect(response.body).to include("Usar sugestão: B3SA3")
    expect(response.body).to include("Nenhum recebível foi criado ainda.")
  ensure
    file&.tempfile&.close!
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
    expect(income_import.rows.first["source_classification"]).to eq("dividends")
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

  it "saves manual classifications and asset selections without creating incomes" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    expect do
      patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
        row_classifications: { "2" => "dividends", "3" => "dividends" },
        row_asset_ids: { "2" => asset.id.to_s, "3" => asset.id.to_s }
      }
    end.not_to change(Investments::Income, :count)

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    rows = income_import.reload.rows
    expect(rows).to all(include("asset_id" => asset.id))
    expect(income_import.summary["possible_duplicate"]).to eq(0)
  ensure
    file&.tempfile&.close!
  end

  it "does not flag a JCP and reimbursement event as the same source event" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
      row_classifications: { "2" => "jcp", "3" => "jcp" },
      row_asset_ids: { "2" => suggested_asset.id.to_s, "3" => suggested_asset.id.to_s }
    }

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(income_import.reload.rows.map { |row| row["duplicate_type"] }).to all(be_nil)
    expect(income_import.rows.second["source_classification"]).to eq("reimbursement")
  ensure
    file&.tempfile&.close!
  end

  it "rejects an asset that does not exist and keeps the draft unchanged" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
      row_classifications: { "2" => "dividends" },
      row_asset_ids: { "2" => "999999" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Selecione um ativo válido para a linha 2")
    expect(income_import.reload.rows.first["asset_id"]).to be_nil
  ensure
    file&.tempfile&.close!
  end

  it "allows ignoring a line without treating it as a pending income" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
      selection_submitted: "1",
      selected_lines: ["2"],
      row_classifications: { "2" => "dividends" },
      row_asset_ids: { "2" => asset.id.to_s }
    }

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(income_import.reload.rows.second).to include("status" => "ignored", "requires_review" => false)
  ensure
    file&.tempfile&.close!
  end

  it "validates only the rows selected for import" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
      selection_submitted: "1",
      selected_lines: ["2"],
      row_classifications: { "2" => "dividends" },
      row_asset_ids: { "2" => asset.id.to_s }
    }

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(income_import.reload.rows.first).to include("status" => "valid", "requires_review" => false)
    expect(income_import.rows.second).to include("status" => "ignored", "ignored_reason" => "Não selecionada para importação.")
  ensure
    file&.tempfile&.close!
  end

  it "marks an exact match with an existing income as a confirmed duplicate" do
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 1.51,
      tax_amount: 0,
      payment_date: Date.new(2026, 10, 15)
    )
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    patch investments_portfolio_income_import_update_path(portfolio, income_import), params: {
      selection_submitted: "1",
      selected_lines: ["2"],
      row_classifications: { "2" => "dividends" },
      row_asset_ids: { "2" => asset.id.to_s }
    }

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(income_import.reload.rows.first).to include("duplicate_type" => "confirmed")
    expect(income_import.summary["confirmed_duplicate"]).to eq(1)
  ensure
    file&.tempfile&.close!
  end

  it "confirms selected rows atomically and creates incomes" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last

    expect do
      post investments_portfolio_income_import_confirm_path(portfolio, income_import), params: {
        selection_submitted: "1",
        selected_lines: ["2"],
        row_classifications: { "2" => "dividends" },
        row_asset_ids: { "2" => asset.id.to_s }
      }
    end.to change(Investments::Income, :count).by(1)

    expect(response).to redirect_to(investments_portfolio_path(portfolio))
    expect(income_import.reload.status).to eq("completed")
    expect(Investments::Income.last).to have_attributes(
      portfolio: portfolio,
      asset: asset,
      income_type: "dividends",
      gross_amount: BigDecimal("1.51"),
      net_amount: BigDecimal("1.51"),
      payment_date: Date.new(2026, 10, 15)
    )
  ensure
    file&.tempfile&.close!
  end

  it "does not replay a completed income import" do
    file = upload
    post investments_portfolio_income_import_create_path(portfolio), params: { income_import: { file: file } }, as: :multipart
    income_import = Investments::IncomeImport.last
    params = {
      selection_submitted: "1",
      selected_lines: ["2"],
      row_classifications: { "2" => "dividends" },
      row_asset_ids: { "2" => asset.id.to_s }
    }
    post investments_portfolio_income_import_confirm_path(portfolio, income_import), params: params

    expect do
      post investments_portfolio_income_import_confirm_path(portfolio, income_import), params: params
    end.not_to change(Investments::Income, :count)

    expect(response).to redirect_to(investments_portfolio_income_import_preview_path(portfolio, income_import))
    expect(flash[:alert]).to include("já foi confirmada")
  ensure
    file&.tempfile&.close!
  end

  it "creates one income with the associated donor fee as tax" do
    income_import = portfolio.income_imports.create!(
      original_filename: "income.xlsx",
      rows: [
        {
          "line_number" => 2,
          "movement_date" => "2026-10-15",
          "settlement_date" => "2026-10-15",
          "description" => "Crédito Ref. Taxa de Remuneração BTC EMBJ",
          "amount" => "10.00",
          "classification" => "stock_lending",
          "asset_id" => asset.id,
          "status" => "valid",
          "paired_line_number" => 3
        },
        {
          "line_number" => 3,
          "movement_date" => "2026-10-15",
          "amount" => "-1.00",
          "classification" => "fee",
          "pair_role" => "tax",
          "status" => "ignored"
        }
      ],
      summary: { "valid" => 1, "ignored" => 1 },
      expires_at: 1.hour.from_now
    )

    result = Investments::IncomeImports::Confirmer.call(income_import: income_import)

    expect(result).to be_success
    expect(Investments::Income.last).to have_attributes(
      gross_amount: BigDecimal("10.00"),
      tax_amount: BigDecimal("1.00"),
      net_amount: BigDecimal("9.00")
    )
  end

  it "does not expose another user's portfolio" do
    other_user = User.create!(name: "Other", email: "other-income-import@example.com", password: "password123")
    other_portfolio = Investments::Portfolio.create!(name: "Outra", user: other_user)

    get investments_portfolio_income_import_path(other_portfolio)

    expect(response).to redirect_to(root_path)
  end
end
