require "rails_helper"

RSpec.describe Investments::IncomeImports::XlsxParser do
  UploadedFile = Struct.new(:content, :original_filename) do
    def read
      content
    end
  end

  def xlsx(rows)
    worksheet = rows.each_with_index.map do |values, row_index|
      cells = values.each_with_index.filter_map do |value, column_index|
        next if value.nil?

        column = ("A".ord + column_index).chr
        if value.is_a?(Numeric)
          "<c r=\"#{column}#{row_index + 1}\"><v>#{value}</v></c>"
        else
          escaped = CGI.escapeHTML(value.to_s)
          "<c r=\"#{column}#{row_index + 1}\" t=\"inlineStr\"><is><t>#{escaped}</t></is></c>"
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

  def parse(rows)
    described_class.call(file: UploadedFile.new(xlsx(rows), "income.xlsx"))
  end

  it "parses the brokerage movement table and classifies income rows" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)", "Saldo (R$)"],
      [46310, 46310, "DIVIDENDOS DE CLIENTES COCA34 S/ 5", "1,51", "238,96"],
      [46310, 46310, "JUROS S/ CAPITAL DE CLIENTES B3SA3 S/ 3", "0,19", "239,15"],
      [46310, 46310, "RENDIMENTOS DE CLIENTES MXRF11 S/ 100", "10,00", "249,15"],
      [46310, 46310, "Crédito Ref. Taxa de Remuneração BTC XPLG", "0,08", "249,23"]
    ])

    expect(result).to be_valid
    expect(result.valid_rows.map(&:classification)).to eq(%w[dividends jcp fii_income stock_lending])
    expect(result.valid_rows.map(&:symbol)).to eq(%w[COCA34 B3SA3 MXRF11 XPLG])
    expect(result.valid_rows.first.movement_date).to eq(Date.new(2026, 10, 15))
  end

  it "marks reimbursements for manual review and classifies taxes and fees separately" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "AMORTIZAÇÃO - TESOURO DIRETO", "0,79"],
      [46310, 46310, "IRRF AMORTIZAÇÃO - TESOURO DIRETO", "-0,03"],
      [46310, 46310, "Taxa de intermediação doador XPLG11", "-0,04"],
      [46310, 46310, "CREDITO DE REEMBOLSO DE EVENTO BRXPLGCTF002", "0,82"]
    ])

    expect(result.valid_rows.map(&:classification)).to eq(%w[amortization tax fee reimbursement])
    expect(result.valid_rows.last.requires_review).to be(true)
    expect(result.valid_rows.last.symbol).to be_nil
  end

  it "links a securities lending credit to its matching donor fee" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "Crédito Ref. Taxa de Remuneração BTC EMBJ", "10,00"],
      [46310, 46310, "Taxa de intermediação doador EMBJ3", "-1,00"]
    ])

    gross, fee = result.rows
    expect(gross).to have_attributes(pair_role: "gross", paired_line_number: fee.line_number)
    expect(fee).to have_attributes(pair_role: "tax", paired_line_number: gross.line_number)
  end

  it "keeps the base ticker as a suggestion for securities lending credits" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "Crédito Ref. Taxa de Remuneração BTC XPLG", "0,08"]
    ])

    expect(result.rows.first).to have_attributes(symbol: "XPLG", symbol_suggestion: "XPLG")
  end

  it "stops at a no-movements marker and rejects files without the movement header" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "DIVIDENDOS DE CLIENTES COCA34 S/ 5", "1,51"],
      [nil, nil, "Não há lançamentos para o período", nil],
      [46310, 46310, "DIVIDENDOS DE CLIENTES B3SA3 S/ 3", "0,19"]
    ])

    expect(result.valid_rows.size).to eq(1)

    missing_header = parse([["Data", "Descrição", "Valor"], [46310, "Dividendos", "1,00"]])
    expect(missing_header).not_to be_valid
    expect(missing_header.errors.first).to include("Cabeçalho")
  end

  it "marks treasury direct movements as unsupported" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "AMORTIZAÇÃO - TESOURO DIRETO", "0,79"]
    ])

    expect(result.rows.first.unsupported_reason).to eq("Tesouro Direto ainda não é suportado.")
  end

  it "keeps a corporate event issuer as an unvalidated asset suggestion" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "CREDITO DE REEMBOLSO DE EVENTO BRB3SAACNOR6", "0,30"]
    ])

    expect(result.rows.first.symbol).to be_nil
    expect(result.rows.first.symbol_suggestion).to eq("B3SA")
  end

  it "preserves the source description and normalizes repeated whitespace" do
    result = parse([
      ["Movimentação", "Liquidação", "Lançamento", "Valor (R$)"],
      [46310, 46310, "  CREDITO   DE REEMBOLSO\n DE EVENTO   BRB3SAACNOR6  ", "0,30"]
    ])

    row = result.rows.first
    expect(row.source_description).to include("CREDITO   DE REEMBOLSO")
    expect(row.description).to eq("CREDITO DE REEMBOLSO DE EVENTO BRB3SAACNOR6")
    expect(row.source_event_identifier).to eq("BRB3SAACNOR6")
  end
end
