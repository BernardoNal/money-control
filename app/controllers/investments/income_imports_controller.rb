module Investments
  class IncomeImportsController < ApplicationController
    before_action :set_portfolio
    before_action :set_income_import, only: :show

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

    private

    def set_portfolio
      @portfolio = current_user.investment_portfolios.find(params[:portfolio_id])
    end

    def set_income_import
      @income_import = @portfolio.income_imports.find(params[:id])
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
        "requires_review" => row.requires_review,
        "status" => row.status.to_s,
        "errors" => row.errors,
        "ignored_reason" => row.ignored_reason
      }
    end

    def summary_for(rows)
      rows.group_by { |row| row.status.to_s }.transform_values(&:size).merge(
        "requires_review" => rows.count(&:requires_review)
      )
    end
  end
end
