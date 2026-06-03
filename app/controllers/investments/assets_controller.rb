module Investments
  class AssetsController < ApplicationController
    before_action :set_asset, only: %i[show edit update]

    def index
      @selected_category = permitted_category(params[:category])
      @categories = category_options
      @assets = Investments::Asset.order(:symbol)
      @assets = @assets.where(category: @selected_category) if @selected_category.present?
    end

    def show
    end

    def new
      @asset = Investments::Asset.new
      @subcategories = subcategory_options
      @categories = category_options
      render :form
    end

    def create
      @asset = Investments::Asset.new(asset_params)
      @categories = category_options

      if @asset.save
        redirect_to investments_asset_path(@asset), notice: "Ativo criado com sucesso."
      else
        render :form, status: :unprocessable_entity
      end
    end

    def edit
      @categories = category_options
      @subcategories = subcategory_options
      render :form
    end

    def update
      @categories = category_options

      if @asset.update(asset_params)
        redirect_to investments_asset_path(@asset), notice: "Ativo alterado com sucesso."
      else
        render :form, status: :unprocessable_entity
      end
    end

    private

    def asset_params
      params.require(:investments_asset).permit(:name, :symbol, :category, :currency, :active)
    end

    def set_asset
      @asset = Investments::Asset.find(params[:id])
    end

    def category_options
      Investments::Asset.categories.keys.map { |key| [key.humanize, key] }
    end

    def subcategory_options
      Investments::Asset.subcategories.keys.map { |key| [key.humanize, key] }
    end

    def permitted_category(value)
      return if value.blank?
      return value if Investments::Asset.categories.key?(value)

      nil
    end
  end
end
