require "prawn"
require "prawn/table"

module Investments
  class IncomeTaxReportPdf
    def self.call(report:, user: nil)
      new(report: report, user: user).call
    end

    def initialize(report:, user: nil)
      @report = report
      @user = user
    end

    def call
      document = Prawn::Document.new(page_size: "A4", margin: 36)
      configure_font(document)
      render_header(document)

      if report.asset_groups.empty?
        render_empty_state(document)
      else
        report.asset_groups.each_with_index do |asset_group, index|
          render_asset_group(document, asset_group, index: index)
        end
      end

      document.render
    end

    private

    attr_reader :report, :user

    # Keep the PDF hierarchy aligned with the on-screen report: asset, income type, records.
    def render_header(document)
      render_logo(document)
      document.bounding_box([0, document.cursor], width: document.bounds.width - 64, height: 72) do
        document.fill_color "000080"
        document.text "Relatório anual de proventos", size: 18, style: :bold
        document.move_down 6
        document.fill_color "808000"
        document.text "Ano: #{report.year}", size: 11
        document.fill_color "334155"
        document.text "Contribuinte: #{user_name}", size: 10
      end
      document.fill_color "000000"
      document.move_down 22
      document.stroke_color "CBD5E1"
      document.stroke_horizontal_rule
      document.move_down 14
      document.formatted_text totals_summary, size: 10
      document.fill_color "000000"
      document.move_down 18
    end

    def render_logo(document)
      logo_path = Rails.root.join("app/assets/images/$$$.png")
      return unless File.file?(logo_path)

      top = document.cursor
      document.image logo_path, at: [document.bounds.width - 42, top], width: 42
      document.text_box "Money Control",
                       at: [document.bounds.width - 150, top - 12],
                       width: 100,
                       height: 18,
                       align: :right,
                       size: 10,
                       style: :bold,
                       color: "000080"
    end

    def render_asset_group(document, asset_group, index:)
      if document.cursor < 150
        document.start_new_page
      elsif index.positive?
        document.move_down 36
      end

      document.fill_color "2563EB"
      document.text "#{asset_group.asset.symbol} - #{asset_group.asset.name}", size: 14, style: :bold
      document.move_down 4
      document.fill_color "047857"
      document.text "Total líquido: #{currency(asset_group.totals[:net_amount])}", size: 10
      document.fill_color "000000"
      document.move_down 12

      asset_group.income_type_groups.each do |type_group|
        render_income_type_group(document, type_group)
      end

      document.stroke_color "808000"
      document.stroke_horizontal_rule
      document.stroke_color "000000"
      document.move_down 12
    end

    def render_income_type_group(document, type_group)
      document.fill_color "808000"
      document.text type_group.label, size: 11, style: :bold
      document.move_down 4
      document.formatted_text subgroup_summary(type_group), size: 8
      document.fill_color "000000"
      document.move_down 6

      document.table(income_rows(type_group),
                     header: true,
                     width: document.bounds.width,
                     cell_style: { size: 8, padding: 4, borders: %i[top bottom], border_color: "CBD5E1", text_color: "334155" },
                     row_colors: ["E8EEF8", "FFFFFF"])
      document.move_down 14
    end

    def income_rows(type_group)
      headers = ["Pagamento", "Referência", "Bruto", "Impostos", "Líquido"]
      rows = type_group.incomes.map do |income|
        [
          format_date(income.payment_date),
          format_date(income.reference_date),
          currency(income.gross_amount),
          currency(income.tax_amount),
          currency(income.net_amount)
        ]
      end

      [headers] + rows
    end

    def render_empty_state(document)
      document.move_down 18
      document.text "Nenhum provento encontrado para #{report.year}.", size: 12
    end

    def configure_font(document)
      font_path = ENV["INCOME_REPORT_FONT_PATH"].presence || "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
      return unless File.file?(font_path)

      document.font_families.update("IncomeReport" => { normal: font_path, bold: font_path })
      document.font("IncomeReport")
    end

    def user_name
      user&.name.presence || user&.email.presence || "Usuário autenticado"
    end

    def totals_summary
      [
        { text: "Totais do ano | ", color: "475569" },
        { text: "Bruto: #{currency(report.totals[:gross_amount])}", color: "334155" },
        { text: " | Impostos: #{currency(report.totals[:tax_amount])}", color: "B91C1C" },
        { text: " | Líquido: #{currency(report.totals[:net_amount])}", color: "047857" }
      ]
    end

    def subgroup_summary(type_group)
      [
        { text: "Bruto: #{currency(type_group.totals[:gross_amount])}", color: "334155" },
        { text: " | Impostos: #{currency(type_group.totals[:tax_amount])}", color: "B91C1C" },
        { text: " | Líquido: #{currency(type_group.totals[:net_amount])}", color: "047857" }
      ]
    end

    def currency(amount)
      ActiveSupport::NumberHelper.number_to_currency(
        amount,
        unit: "R$ ",
        separator: ",",
        delimiter: "."
      )
    end

    def format_date(value)
      value.present? ? I18n.l(value) : "-"
    end
  end
end
