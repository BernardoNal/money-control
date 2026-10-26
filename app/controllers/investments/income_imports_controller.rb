module Investments
  class IncomeImportsController < ApplicationController
    before_action :set_portfolio
    before_action :set_income_import, only: %i[show update confirm]
    before_action :load_review_collections, only: %i[new create show update confirm]

    def new
      @income_import = @portfolio.income_imports.new
    end

    def create
      file = params.dig(:income_import, :file)
      if file.blank?
        @income_import = @portfolio.income_imports.new
        @upload_error = "Selecione um arquivo XLSX."
        return render :new, status: :unprocessable_entity
      end

      result = IncomeImports::XlsxParser.call(file: file)
      if result.errors.any?
        @income_import = @portfolio.income_imports.new
        @upload_error = result.errors.to_sentence
        return render :new, status: :unprocessable_entity
      end

      @income_import = @portfolio.income_imports.new(
        original_filename: File.basename(file.original_filename.to_s),
        rows: result.rows.map { |row| serialize_row(row) },
        summary: summary_for(result.rows),
        expires_at: 1.hour.from_now
      )

      if @income_import.save
        redirect_to investments_portfolio_income_import_preview_path(@portfolio, @income_import),
                    notice: "Arquivo carregado para revisão. Nenhum recebível foi criado."
      else
        @upload_error = @income_import.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def update
      if @income_import.pending?
        rows, errors = reviewed_rows
        return render_review_error(rows, errors) if errors.any?

        @income_import.update!(rows: rows, summary: summary_for_rows(rows))
      end

      redirect_to investments_portfolio_income_import_preview_path(@portfolio, @income_import),
                  notice: "Revisão dos recebíveis atualizada."
    end

    def confirm
      if @income_import.pending? && review_changes_submitted?
        rows, errors = reviewed_rows
        return render_review_error(rows, errors) if errors.any?

        @income_import.update!(rows: rows, summary: summary_for_rows(rows))
      end

      result = IncomeImports::Confirmer.call(income_import: @income_import)
      if result.success?
        redirect_to investments_portfolio_path(@portfolio), notice: result.message
      else
        redirect_to investments_portfolio_income_import_preview_path(@portfolio, @income_import), alert: result.message
      end
    end

    private

    def set_portfolio
      @portfolio = current_user.investment_portfolios.find(params[:portfolio_id])
    end

    def set_income_import
      @income_import = @portfolio.income_imports.find(params[:id])
    end

    def load_review_collections
      @assets = Investments::Asset.order(:symbol)
      @assets_by_id = @assets.index_by(&:id)
      @assets_by_symbol = @assets.index_by { |asset| asset.symbol.upcase }
      @assets_by_suggestion = unique_assets_by_suggestion(@assets)
      @income_types = Investments::Income.income_types.keys.map do |income_type|
        [I18n.t("activerecord.attributes.investments/income.income_types.#{income_type}", default: income_type.humanize), income_type]
      end
    end

    # Only expose a suggestion when the issuer prefix resolves to one asset;
    # ambiguous matches must remain a manual choice in the import review.
    def unique_assets_by_suggestion(assets)
      assets.group_by { |asset| asset.symbol.to_s.upcase.sub(/\d+\z/, "") }
        .filter_map { |suggestion, matches| [suggestion, matches.first] if matches.one? }
        .to_h
    end

    def serialize_row(row)
      {
        "line_number" => row.line_number,
        "movement_date" => row.movement_date&.iso8601,
        "settlement_date" => row.settlement_date&.iso8601,
        "description" => row.description,
        "amount" => row.amount&.to_s("F"),
        "balance" => row.balance&.to_s("F"),
        "classification" => row.classification,
        "symbol" => row.symbol,
        "symbol_suggestion" => row.symbol_suggestion,
        "requires_review" => row.requires_review,
        "status" => row.status.to_s,
        "errors" => row.errors,
        "ignored_reason" => row.ignored_reason,
        "pair_role" => row.pair_role,
        "paired_line_number" => row.paired_line_number,
        "unsupported_reason" => row.unsupported_reason
      }
    end

    def summary_for(rows)
      summary_for_rows(rows.map { |row| serialize_row(row) })
    end

    def summary_for_rows(rows)
      rows.group_by { |row| row["status"] }.transform_values(&:size).merge(
        "requires_review" => rows.count { |row| row["requires_review"] },
        "unsupported" => rows.count { |row| row["unsupported_reason"].present? },
        "possible_duplicate" => rows.count { |row| row["possible_duplicate"] },
        "confirmed_duplicate" => rows.count { |row| row["confirmed_duplicate"] }
      )
    end

    def apply_review_changes
      classifications = permitted_review_values(:row_classifications)
      asset_ids = permitted_review_values(:row_asset_ids)
      selected_lines = permitted_lines(:selected_lines)
      selection_submitted = params[:selection_submitted].present?
      errors = []

      rows = @income_import.rows.map do |row|
        next row unless %w[valid ignored].include?(row["status"])

        line = row["line_number"].to_s
        classification = classifications[line].presence || row["classification"]
        classification = nil if classification == "ignored"
        asset_id = asset_ids[line].presence

        if selection_submitted && !selected_lines.include?(line)
          row.merge(
            "classification" => row["classification"],
            "asset_id" => nil,
            "asset_symbol" => nil,
            "requires_review" => false,
            "ignored_reason" => "Não selecionada para importação.",
            "status" => "ignored"
          )
        else
          asset = find_asset(asset_id, row)
          errors << "Selecione um tipo de provento para a linha #{line}." unless Investments::Income.income_types.key?(classification)
          errors << "Selecione um ativo válido para a linha #{line}." unless asset
          row.merge(
            "classification" => classification,
            "asset_id" => asset&.id,
            "asset_symbol" => asset&.symbol,
            "requires_review" => !errors_for_row?(classification, asset),
            "ignored_reason" => nil
          )
        end
      end

      [rows, errors]
    end

    def reviewed_rows
      rows, errors = apply_review_changes
      return [rows, errors] if errors.any?

      # Re-run domain validation on every save and confirm request so a stale
      # preview cannot bypass asset, date or duplicate checks.
      validation = IncomeImports::ReviewValidator.call(portfolio: @portfolio, rows: rows)
      [validation.rows, validation.errors]
    end

    def render_review_error(rows, errors)
      flash.now[:alert] = errors.to_sentence
      @income_import.rows = rows
      render :show, status: :unprocessable_entity
    end

    def review_changes_submitted?
      params[:selection_submitted].present? || params[:row_classifications].present? || params[:row_asset_ids].present?
    end

    def find_asset(asset_id, row)
      return Investments::Asset.find_by(id: asset_id) if asset_id.present?

      Investments::Asset.find_by(symbol: row["symbol"].to_s.upcase) if row["symbol"].present?
    end

    def errors_for_row?(classification, asset)
      Investments::Income.income_types.key?(classification) && asset.present?
    end

    def permitted_review_values(key)
      values = params[key]
      values.respond_to?(:permit) ? values.permit!.to_h.transform_keys(&:to_s) : {}
    end

    def permitted_lines(key)
      values = params[key]
      values.respond_to?(:to_unsafe_h) ? values.to_unsafe_h.values.map(&:to_s) : Array(values).map(&:to_s)
    end
  end
end
