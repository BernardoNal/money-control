require "csv"
require "date"

module Transactions
  module Imports
    class CsvParser
      MAX_FILE_SIZE = 5.megabytes
      MAX_ROWS = 5_000

      NormalizedRow = Struct.new(
        :line_number,
        :date,
        :amount,
        :description,
        :category_name,
        :to_whom,
        :document_number,
        :transaction_type,
        :payment_method,
        :status,
        :errors,
        :ignored_reason,
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
        date: %w[data date transaction_date],
        amount: %w[valor amount value],
        description: %w[descricao descrição description historico histórico lancamento lançamento],
        category: %w[categoria category],
        to_whom: %w[recebedor pagador to_whom recipient payer detalhes detail details],
        document_number: %w[n_documento documento document document_number],
        transaction_type: %w[tipo_lancamento tipo_de_lancamento transaction_type type],
        payment_method: %w[forma_pagamento forma_de_pagamento método pagamento payment_method method]
      }.freeze

      REQUIRED_FIELDS = %i[date amount description].freeze
      FIELD_LABELS = {
        date: "Data",
        amount: "Valor",
        description: "Descrição"
      }.freeze
      IGNORED_DESCRIPTIONS = {
        "saldo_anterior" => "Saldo bancário.",
        "saldo_do_dia" => "Saldo bancário.",
        "s_a_l_d_o" => "Saldo bancário.",
        "bb_rende_facil" => "Movimentação de investimento fora do escopo."
      }.freeze

      def self.call(file:)
        new(file: file).call
      end

      def initialize(file:)
        @file = file
      end

      def call
        content = read_content
        return Result.new(rows: [], errors: [content[:error]], headers: []) if content[:error]

        csv = CSV.parse(content[:value], headers: true, return_headers: false, col_sep: detect_separator(content[:value]))
        headers = normalize_headers(csv.headers)
        missing_fields = REQUIRED_FIELDS.reject { |field| headers.key?(field) }

        return unsupported_headers_result(headers, missing_fields) if missing_fields.any?
        return too_many_rows_result(headers) if csv.length > MAX_ROWS

        rows = csv.each_with_index.map do |csv_row, index|
          build_row(csv_row, headers, index + 2)
        end

        Result.new(rows: rows, errors: [], headers: headers.keys)
      rescue CSV::MalformedCSVError => e
        Result.new(rows: [], errors: ["Arquivo CSV inválido: #{e.message}"], headers: [])
      rescue ArgumentError, EncodingError => e
        Result.new(rows: [], errors: ["Não foi possível interpretar o arquivo: #{e.message}"], headers: [])
      end

      private

      attr_reader :file

      def read_content
        raw_content = file.read
        return { error: "O arquivo CSV não pode exceder 5 MB." } if raw_content.bytesize > MAX_FILE_SIZE

        bytes = raw_content.dup.force_encoding(Encoding::BINARY)
        utf8_content = bytes.dup.force_encoding(Encoding::UTF_8)
        content = if utf8_content.valid_encoding?
                    utf8_content
                  else
                    bytes.encode(Encoding::UTF_8, Encoding::WINDOWS_1252)
                  end

        { value: content.delete_prefix("\uFEFF") }
      rescue EncodingError
        { error: "O arquivo CSV deve usar codificação UTF-8 ou Windows-1252." }
      end

      # Normalize headers without changing the values that will be persisted.
      def normalize_headers(raw_headers)
        raw_headers.each_with_object({}) do |raw_header, normalized|
          key = normalize_header(raw_header)
          field = HEADER_ALIASES.find { |_name, aliases| aliases.include?(key) }&.first
          normalized[field] ||= raw_header if field
        end
      end

      def normalize_header(value)
        value.to_s.strip.downcase
          .unicode_normalize(:nfkd)
          .encode("ASCII", replace: "")
          .gsub(/[^a-z0-9]+/, "_")
          .sub(/\A_+|_+\z/, "")
      end

      def detect_separator(content)
        first_line = content.lines.first.to_s
        first_line.count(";") > first_line.count(",") ? ";" : ","
      end

      def build_row(csv_row, headers, line_number)
        values = headers.transform_values { |header| csv_row[header].to_s.strip }
        return ignored_row(line_number) if values.values.all?(&:blank?)
        ignored_reason = IGNORED_DESCRIPTIONS[normalize_header(values[:description])]
        return ignored_row(line_number, ignored_reason) if ignored_reason

        errors = []
        date = parse_date(values[:date], errors)
        amount = parse_amount(values[:amount], errors)
        description = required_value(values[:description], "Descrição", errors)
        category_name = values[:category].presence

        NormalizedRow.new(
          line_number: line_number,
          date: date,
          amount: amount,
          description: description,
          category_name: category_name,
          to_whom: normalize_counterparty(values[:to_whom]),
          document_number: values[:document_number].presence,
          transaction_type: values[:transaction_type].presence,
          payment_method: values[:payment_method].presence,
          status: errors.empty? ? :valid : :invalid,
          errors: errors,
          ignored_reason: nil
        )
      end

      def required_value(value, label, errors)
        return value if value.present?

        errors << "#{label} é obrigatório."
        nil
      end

      def normalize_counterparty(value)
        value.to_s.strip
          .sub(/\A\d{2}\/\d{2}\s+\d{2}:\d{2}\s+/, "")
          .sub(/\A\d{11,14}\s+/, "")
          .presence
      end

      def parse_date(value, errors)
        return errors << "Data é obrigatória." && nil if value.blank?

        ["%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"].each do |format|
          return Date.strptime(value, format)
        rescue Date::Error
          next
        end

        errors << "Data inválida: #{value}."
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

      def ignored_row(line_number, reason = "Linha vazia.")
        NormalizedRow.new(
          line_number: line_number,
          status: :ignored,
          errors: [],
          ignored_reason: reason
        )
      end

      def unsupported_headers_result(headers, missing_fields)
        labels = missing_fields.map { |field| FIELD_LABELS.fetch(field) }
        Result.new(
          rows: [],
          errors: ["Cabeçalho incompatível. Campos obrigatórios ausentes: #{labels.join(", ")}."],
          headers: headers.keys
        )
      end

      def too_many_rows_result(headers)
        Result.new(
          rows: [],
          errors: ["O arquivo CSV não pode exceder #{MAX_ROWS} linhas."],
          headers: headers.keys
        )
      end
    end
  end
end
