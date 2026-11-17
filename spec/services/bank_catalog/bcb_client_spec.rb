require "rails_helper"

RSpec.describe BankCatalog::BcbClient do
  let(:csv_body) do
    <<~CSV
      \uFEFFISPB,Nome_Reduzido,Número_Código,Participa_da_Compe,Acesso_Principal,Nome_Extenso,Início_da_Operação
      00000000,BCO DO BRASIL S.A.,001,Sim,RSFN,Banco do Brasil S.A.,22/04/2002
      00000208,BRB - BCO DE BRASILIA S.A.,070,Sim,RSFN,BRB - BANCO DE BRASILIA S.A.,22/04/2002
      00038121,Selic,n/a,Não,RSFN,Banco Central do Brasil - Selic,22/04/2002
    CSV
  end

  it "normalizes the official CSV into catalog records" do
    response = instance_double(Net::HTTPResponse, code: "200", body: csv_body)
    http = class_double(Net::HTTP, get_response: response)

    records = described_class.call(http: http, source_url: "https://example.test/banks.csv")

    expect(records).to contain_exactly(
      {
        bank_code: "001",
        ispb: "00000000",
        name: "Banco do Brasil S.A.",
        short_name: "BCO DO BRASIL S.A.",
        active: true
      },
      {
        bank_code: "070",
        ispb: "00000208",
        name: "BRB - BANCO DE BRASILIA S.A.",
        short_name: "BRB - BCO DE BRASILIA S.A.",
        active: true
      },
      {
        bank_code: "n/a",
        ispb: "00038121",
        name: "Banco Central do Brasil - Selic",
        short_name: "Selic",
        active: true
      }
    )
  end

  it "raises a source error for an unsuccessful response" do
    response = instance_double(Net::HTTPResponse, code: "503")
    http = class_double(Net::HTTP, get_response: response)

    expect do
      described_class.call(http: http, source_url: "https://example.test/banks.csv")
    end.to raise_error(BankCatalog::BcbClient::Error, "Banco Central returned HTTP 503")
  end

  it "raises a source error when the request times out" do
    http = class_double(Net::HTTP)
    allow(http).to receive(:get_response).and_raise(Net::ReadTimeout, "read timeout")

    expect do
      described_class.call(http: http, source_url: "https://example.test/banks.csv")
    end.to raise_error(BankCatalog::BcbClient::Error, /Unable to fetch Banco Central bank catalog/)
  end
end
