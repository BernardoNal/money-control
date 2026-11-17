# frozen_string_literal: true

require "csv"
require "net/http"
require "uri"

module BankCatalog
  class BcbClient
    class Error < StandardError; end

    SOURCE_URL = "https://www.bcb.gov.br/content/estabilidadefinanceira/str1/ParticipantesSTR.csv"

    def self.call(http: Net::HTTP, source_url: SOURCE_URL)
      new(http: http, source_url: source_url).call
    end

    def initialize(http:, source_url:)
      @http = http
      @source_url = source_url
    end

    def call
      # The source is fetched only during an explicit synchronization task;
      # application requests use the local catalog instead of calling the BCB.
      response = @http.get_response(URI.parse(@source_url))
      raise Error, "Banco Central returned HTTP #{response.code}" unless response.code.to_i.between?(200, 299)

      parse(response.body)
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Unable to fetch Banco Central bank catalog: #{e.message}"
    rescue CSV::MalformedCSVError => e
      raise Error, "Unable to parse Banco Central bank catalog: #{e.message}"
    end

    private

    def parse(body)
      # The BCB publishes a UTF-8 CSV with a BOM and keeps rows without a
      # bank number (for example, infrastructure participants) in the same file.
      normalized_body = body.dup.force_encoding(Encoding::UTF_8).sub(/\A\uFEFF/, "")

      CSV.parse(normalized_body, headers: true).filter_map do |row|
        {
          bank_code: row["Número_Código"],
          ispb: row["ISPB"],
          name: row["Nome_Extenso"],
          short_name: row["Nome_Reduzido"],
          active: true
        }
      end
    end
  end
end
