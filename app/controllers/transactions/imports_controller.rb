module Transactions
  class ImportsController < ApplicationController
    before_action :set_account
    before_action :set_categories
    before_action :set_transaction_import, only: %i[show update confirm cancel]

    def new
      @transaction_import = @account.transaction_imports.new
    end

    def create
      file = params.dig(:transaction_import, :file)
      if file.blank?
        @transaction_import = @account.transaction_imports.new
        @upload_error = "Selecione um arquivo CSV."
        return render :new, status: :unprocessable_entity
      end

      result = Imports::CsvParser.call(file: file)
      if result.errors.any?
        @transaction_import = @account.transaction_imports.new
        @upload_error = result.errors.to_sentence
        return render :new, status: :unprocessable_entity
      end

      @transaction_import = Imports::DraftBuilder.build(
        account: @account,
        filename: File.basename(file.original_filename.to_s),
        result: result,
        default_categories: @uncategorized_categories
      )

      if @transaction_import.save
        redirect_to account_transaction_import_preview_path(@account, @transaction_import),
                    notice: "Arquivo carregado para revisão."
      else
        @upload_error = @transaction_import.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def update
      if apply_review_changes.any?
        flash.now[:alert] = "Uma ou mais categorias não pertencem ao usuário atual."
        return render :show, status: :unprocessable_entity
      end

      redirect_to account_transaction_import_preview_path(@account, @transaction_import),
                  notice: "Categorias da revisão atualizadas."
    end

    def confirm
      if review_changes_submitted? && apply_review_changes.any?
        return redirect_to account_transaction_import_preview_path(@account, @transaction_import),
                           alert: "Uma ou mais categorias não pertencem ao usuário atual."
      end

      result = Imports::Confirmer.call(transaction_import: @transaction_import, user: current_user)

      if result.success?
        redirect_to account_path(@account), notice: result.message
      elsif @transaction_import.status == "expired"
        redirect_to account_transaction_import_preview_path(@account, @transaction_import)
      else
        redirect_to account_transaction_import_preview_path(@account, @transaction_import), alert: result.message
      end
    end

    def cancel
      if @transaction_import.cancelable?
        @transaction_import.update!(status: "cancelled")
        redirect_to account_path(@account), notice: "Importação cancelada."
      else
        redirect_to account_transaction_import_preview_path(@account, @transaction_import),
                    alert: "Esta importação não pode mais ser cancelada."
      end
    end

    private

    def set_account
      # Always resolve the account through the current user's association;
      # never trust only the account_id sent by the form.
      @account = current_user.accounts.find(params[:account_id])
    end

    def set_categories
      @uncategorized_categories = {
        true => Category.uncategorized(income: true),
        false => Category.uncategorized(income: false)
      }
      @categories = Category.for_user(current_user.id).order(:name)
      @categories_by_direction = @categories.group_by(&:is_income)
    end

    def set_transaction_import
      @transaction_import = @account.transaction_imports.find(params[:id])
    end

    def permitted_category_selections
      selections = params[:row_categories]
      selections.respond_to?(:permit) ? selections.permit!.to_h : {}
    end

    def permitted_selected_lines
      selected_lines = params[:selected_lines]
      selected_lines = selected_lines.to_unsafe_h.values if selected_lines.respond_to?(:to_unsafe_h)
      Array(selected_lines).map(&:to_s)
    end

    def permitted_descriptions
      descriptions = params[:row_descriptions]
      descriptions.respond_to?(:permit) ? descriptions.permit!.to_h : {}
    end

    def apply_review_changes
      rows, invalid_category_ids = Imports::DraftBuilder.apply_categories!(
        transaction_import: @transaction_import,
        selections: permitted_category_selections,
        selected_lines: permitted_selected_lines,
        descriptions: permitted_descriptions,
        categories: @categories,
        default_categories: @uncategorized_categories
      )
      return invalid_category_ids if invalid_category_ids.any?

      @transaction_import.update!(rows: rows)
      []
    end

    def review_changes_submitted?
      params[:row_categories].present? || params[:selected_lines].present? || params[:row_descriptions].present?
    end
  end
end
