require "rails_helper"

RSpec.describe Transactions::Imports::CsvParser do
  UploadedFile = Struct.new(:content, :original_filename) do
    def read
      content
    end
  end

  def parse(csv)
    described_class.call(file: UploadedFile.new(csv, "transactions.csv"))
  end

  it "normalizes Portuguese headers, Brazilian amounts and dates" do
    result = parse(<<~CSV)
      Data;Valor;Descrição;Categoria;Recebedor;Forma de pagamento
      15/02/2026;R$ 1.234,56;Mercado;Alimentação;Supermercado;Cartão
    CSV

    row = result.valid_rows.first

    expect(result).to be_valid
    expect(row.date).to eq(Date.new(2026, 2, 15))
    expect(row.amount).to eq(BigDecimal("1234.56"))
    expect(row.description).to eq("Mercado")
    expect(row.category_name).to eq("Alimentação")
    expect(row.to_whom).to eq("Supermercado")
    expect(row.payment_method).to eq("Cartão")
  end

  it "normalizes the Banco do Brasil statement format without requiring a category" do
    result = parse(<<~CSV)
      Data,"Lançamento","Detalhes","N° documento","Valor","Tipo Lançamento"
      09/09/2026,"Pix - Recebido","09/09 17:53 ADRIAN RANIER","9175","110,00","Entrada"
    CSV

    row = result.valid_rows.first

    expect(result).to be_valid
    expect(row.category_name).to be_nil
    expect(row.description).to eq("Pix - Recebido")
    expect(row.to_whom).to eq("09/09 17:53 ADRIAN RANIER")
    expect(row.document_number).to eq("9175")
    expect(row.transaction_type).to eq("Entrada")
  end

  it "supports English headers and ISO dates" do
    result = parse(<<~CSV)
      date,amount,description,category
      2026-03-01,-45.90,Coffee,Food
    CSV

    expect(result.valid_rows.first.amount).to eq(BigDecimal("-45.90"))
    expect(result.valid_rows.first.date).to eq(Date.new(2026, 3, 1))
  end

  it "reports invalid rows without dropping the original line number" do
    result = parse(<<~CSV)
      data;valor;descricao;categoria
      data-invalida;abc;Compra;Mercado
    CSV

    row = result.invalid_rows.first

    expect(result).not_to be_valid
    expect(row.line_number).to eq(2)
    expect(row.errors).to include("Data inválida: data-invalida.", "Valor inválido: abc.")
  end

  it "reports blank rows as intentionally ignored" do
    result = parse("data,valor,descricao,categoria\n\n")

    expect(result.ignored_rows.size).to eq(1)
    expect(result.ignored_rows.first.ignored_reason).to eq("Linha vazia.")
  end

  it "rejects files without the required headers" do
    result = parse("data,valor\n01/01/2026,10\n")

    expect(result).not_to be_valid
    expect(result.errors.first).to include("Descrição")
  end

  it "marks bank balances and investment movements as ignored" do
    result = parse(<<~CSV)
      data,lancamento,valor
      21/08/2026,Saldo Anterior,"0,00"
      09/09/2026,BB Rende Fácil,"-110,00"
      09/09/2026,Pix - Recebido,"110,00"
    CSV

    expect(result.ignored_rows.map(&:ignored_reason)).to contain_exactly(
      "Saldo bancário.",
      "Movimentação de investimento fora do escopo."
    )
    expect(result.valid_rows.size).to eq(1)
  end

  it "accepts an UTF-8 BOM" do
    result = parse("\uFEFFdata,amount,description,category\n2026-01-01,10,Compra,Food\n")

    expect(result).to be_valid
    expect(result.valid_rows.size).to eq(1)
  end
end
