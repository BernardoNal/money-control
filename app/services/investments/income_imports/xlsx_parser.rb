require "bigdecimal"
require "date"
require "rexml/document"
require "zip"

module Investments
  module IncomeImports
    class XlsxParser
      MAX_FILE_SIZE = 10.megabytes
      MAX_ROWS = 5_000
      EXCEL_EPOCH = Date.new(1899, 12, 30)

      NormalizedRow = Struct.new(
        :line_number,
        :movement_date,
        :settlement_date,
        :description,
        :amount,
        :balance,
        :classification,
        :symbol,
        :requires_review,
        :status,
        :errors,
        :ignored_reason,
        :pair_role,
        :paired_line_number,
        :unsupported_reason,
        keyword_init: true
      )

      Result = Struct.new(:rows, :errors, :headers, keyword_init: true) do
        def valid_rows
          rows.select { |row| row.status == :valid }
        end

        def invalid_rows
          rows.select { |row| row.status == :invalid }
        end

        def ignored_rows
          rows.select { |row| row.status == :ignored }
        end

        def valid?
          errors.empty? && rows.none? { |row| row.status == :invalid }
        end
      end

      HEADER_ALIASES = {
        movement_date: ["movimentacao", "data", "movement_date"],
        settlement_date: ["liquidacao", "settlement", "settlement_date"],
        description: ["lancamento", "descricao", "description", "movement"],
        amount: ["valor_r", "valor", "amount"],
        balance: ["saldo_r", "saldo", "balance"]
      }.freeze

      def self.call(file:)
        new(file: file).call
      end

      def initialize(file:)
        @file = file
      end

      def call
        content = file.read
        return Result.new(rows: [], errors: ["O arquivo XLSX não pode exceder 10 MB."], headers: []) if content.bytesize > MAX_FILE_SIZE

        result = nil
        Zip::File.open_buffer(content) do |workbook|
          sheet_entry = workbook.find_entry("xl/worksheets/sheet1.xml")
          result = Result.new(rows: [], errors: ["O arquivo XLSX não possui uma primeira planilha válida."], headers: []) and next unless sheet_entry

          shared_strings = parse_shared_strings(workbook)
          sheet_rows = parse_sheet(sheet_entry.get_input_stream.read, shared_strings)
          result = parse_data_rows(sheet_rows)
        end
        result
      rescue Zip::Error, REXML::ParseException => e
        Result.new(rows: [], errors: ["Arquivo XLSX inválido: #{e.message}"], headers: [])
      rescue ArgumentError, EncodingError => e
        Result.new(rows: [], errors: ["Não foi possível interpretar o arquivo XLSX: #{e.message}"], headers: [])
      end

      private

      attr_reader :file

      def parse_shared_strings(workbook)
        entry = workbook.find_entry("xl/sharedStrings.xml")
        return [] unless entry

        document = REXML::Document.new(entry.get_input_stream.read)
        document.get_elements("//*[local-name()='si']").map do |item|
          item.get_elements(".//*[local-name()='t']").map(&:text).join
        end
      end

      def parse_sheet(xml, shared_strings)
        document = REXML::Document.new(xml)
        document.get_elements("//*[local-name()='row']").map do |row|
          cells = row.elements.to_a.select { |element| element.name == "c" }.each_with_object({}) do |cell, values|
            values[column_name(cell.attributes["r"])] = cell_value(cell, shared_strings)
          end
          { line_number: row.attributes["r"].to_i, cells: cells }
        end
      end

      def cell_value(cell, shared_strings)
        type = cell.attributes["t"]
        if type == "s"
          index = cell.elements["v"]&.text.to_i
          return shared_strings[index]
        end

        if type == "inlineStr"
          return cell.get_elements(".//*[local-name()='t']").map(&:text).join
        end

        cell.elements["v"]&.text
      end

      def column_name(reference)
        reference.to_s[/[A-Z]+/]
      end

      def parse_data_rows(sheet_rows)
        header_row = sheet_rows.find { |row| header_row?(row[:cells]) }
        return Result.new(rows: [], errors: ["Cabeçalho de movimentações não encontrado no arquivo XLSX."], headers: []) unless header_row

        headers = normalize_headers(header_row[:cells])
        return Result.new(rows: [], errors: ["O cabeçalho do XLSX precisa conter lançamento e valor."], headers: headers.keys) unless headers[:description] && headers[:amount]

        rows = []
        sheet_rows.drop_while { |row| row != header_row }.drop(1).each do |row|
          description = row[:cells][headers[:description]].to_s.strip
          break if normalize_header(description).start_with?("nao_ha_lancamentos")

          parsed_row = build_row(row, headers)
          rows << parsed_row if parsed_row
        end

        return Result.new(rows: [], errors: ["O arquivo XLSX não pode exceder #{MAX_ROWS} lançamentos."], headers: headers.keys) if rows.size > MAX_ROWS

        pair_related_rows(rows)

        Result.new(rows: rows, errors: [], headers: headers.keys)
      end

      def header_row?(cells)
        normalized = cells.values.filter_map { |value| normalize_header(value) }
        normalized.include?("lancamento") && normalized.any? { |value| value.start_with?("valor") }
      end

      def normalize_headers(cells)
        cells.each_with_object({}) do |(column, value), headers|
          normalized = normalize_header(value)
          field = HEADER_ALIASES.find { |_name, aliases| aliases.include?(normalized) }&.first
          headers[field] ||= column if field
        end
      end

      def build_row(row, headers)
        description = row[:cells][headers[:description]].to_s.strip
        return nil if description.blank? || normalize_header(description).start_with?("nao_ha_lancamentos")

        errors = []
        movement_date = parse_date(row[:cells][headers[:movement_date]], errors, "Movimentação") if headers[:movement_date]
        settlement_date = parse_date(row[:cells][headers[:settlement_date]], errors, "Liquidação") if headers[:settlement_date]
        amount = parse_amount(row[:cells][headers[:amount]], errors)
        balance = headers[:balance] ? parse_amount(row[:cells][headers[:balance]], []) : nil
        classification = classify(description)
        unsupported_reason = unsupported_reason_for(description)

        NormalizedRow.new(
          line_number: row[:line_number],
          movement_date: movement_date,
          settlement_date: settlement_date,
          description: description,
          amount: amount,
          balance: balance,
          classification: classification,
          symbol: extract_symbol(description),
          requires_review: classification == "reimbursement" || classification == "other",
          status: errors.empty? ? :valid : :invalid,
          errors: errors,
          ignored_reason: nil,
          pair_role: nil,
          paired_line_number: nil,
          unsupported_reason: unsupported_reason
        )
      end

      def unsupported_reason_for(description)
        return unless normalize_header(description).include?("tesouro_direto")

        "Tesouro Direto ainda não é suportado."
      end

      def pair_related_rows(rows)
        lending_rows = rows.select { |row| row.classification == "stock_lending" }
        fee_rows = rows.select { |row| row.classification == "fee" }

        fee_rows.each do |fee_row|
          lending_row = lending_rows.find do |candidate|
            candidate.paired_line_number.nil? &&
              candidate.movement_date == fee_row.movement_date &&
              candidate.symbol.present? &&
              fee_row.symbol.present? &&
              related_symbols?(candidate.symbol, fee_row.symbol)
          end
          next unless lending_row

          lending_row.pair_role = "gross"
          lending_row.paired_line_number = fee_row.line_number
          fee_row.pair_role = "tax"
          fee_row.paired_line_number = lending_row.line_number
        end
      end

      def related_symbols?(gross_symbol, fee_symbol)
        gross_symbol == fee_symbol ||
          (fee_symbol.start_with?(gross_symbol) && fee_symbol.length - gross_symbol.length <= 2)
      end

      def classify(description)
        normalized = normalize_header(description)
        return "dividends" if normalized.start_with?("dividendos_de_clientes")
        return "jcp" if normalized.start_with?("juros_s_capital_de_clientes")
        return "fii_income" if normalized.start_with?("rendimentos_de_clientes")
        return "amortization" if normalized.start_with?("amortizacao")
        return "tax" if normalized.start_with?("irrf") || normalized.start_with?("debito_cblc_irrf")
        return "fee" if normalized.start_with?("taxa_de_intermediacao_doador")
        return "stock_lending" if normalized.start_with?("credito_ref_taxa_de_remuneracao_btc")
        return "reimbursement" if normalized.start_with?("credito_de_reembolso_de_evento")

        "other"
      end

      def extract_symbol(description)
        tokens = description.upcase.scan(/\b[A-Z0-9]{4,6}\b/)
        tokens.find { |token| token.match?(/\A(?=.*[A-Z])(?=.*\d)[A-Z0-9]{4,6}\z/) } || description.upcase[/\bBTC\s+([A-Z]{4,6}\d{0,2})\b/, 1]
      end

      def parse_date(value, errors, label)
        return errors << "#{label} é obrigatória." && nil if value.blank?

        return EXCEL_EPOCH + value.to_f if value.to_s.match?(/\A\d+(\.\d+)?\z/)

        ["%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"].each do |format|
          return Date.strptime(value.to_s, format)
        rescue Date::Error
          next
        end

        errors << "#{label} inválida: #{value}."
        nil
      end

      def parse_amount(value, errors)
        return errors << "Valor é obrigatório." && nil if value.blank?

        normalized = value.to_s.strip.gsub(/R\$|\s/, "")
        normalized = if normalized.include?(",") && (!normalized.include?(".") || normalized.rindex(",") > normalized.rindex("."))
                       normalized.delete(".").tr(",", ".")
                     else
                       normalized.delete(",")
                     end
        BigDecimal(normalized)
      rescue ArgumentError
        errors << "Valor inválido: #{value}."
        nil
      end

      def normalize_header(value)
        value.to_s.strip.downcase
          .unicode_normalize(:nfkd)
          .encode("ASCII", replace: "")
          .gsub(/[^a-z0-9]+/, "_")
          .sub(/\A_+|_+\z/, "")
      end
    end
  end
end
