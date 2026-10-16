module Transactions
  class ImportsController < ApplicationController
    before_action :set_account
    before_action :set_categories
    before_action :set_transaction_import, only: %i[show update]

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
        result: result
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
      selections = permitted_category_selections
      rows, invalid_category_ids = Imports::DraftBuilder.apply_categories!(
        transaction_import: @transaction_import,
        selections: selections,
        categories: @categories
      )

      if invalid_category_ids.any?
        flash.now[:alert] = "Uma ou mais categorias não pertencem ao usuário atual."
        return render :show, status: :unprocessable_entity
      end

      @transaction_import.update!(rows: rows)
      redirect_to account_transaction_import_preview_path(@account, @transaction_import),
                  notice: "Categorias da revisão atualizadas."
    end

    private

    def set_account
      @account = current_user.accounts.find(params[:account_id])
    end

    def set_categories
      @categories = Category.for_user(current_user.id).order(:name)
    end

    def set_transaction_import
      @transaction_import = @account.transaction_imports.find(params[:id])
    end

    def permitted_category_selections
      selections = params[:row_categories]
      selections.respond_to?(:permit) ? selections.permit!.to_h : {}
    end
  end
end
