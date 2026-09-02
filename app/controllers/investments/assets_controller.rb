module Investments
  class AssetsController < ApplicationController
    before_action :set_asset, only: %i[edit update]

    def index
      @total_assets = 5
      @offset = params[:set].to_i % @total_assets == 0 ? params[:set].to_i : 0

      @selected_category = permitted_category(params[:category])
      @selected_subcategory = permitted_subcategory(params[:subcategory])
      @categories = category_options
      @subcategories = subcategory_options
      @assets = Investments::Asset.order(:symbol)
      @assets = @assets.where(category: @selected_category) if @selected_category.present?
      @assets = @assets.where(subcategory: @selected_subcategory) if @selected_subcategory.present?
      @visible_assets = @assets.limit(@total_assets).offset(@offset)
      @asset_prices = build_asset_prices(@visible_assets)
    end

    def new
      @asset = Investments::Asset.new
      @subcategories = form_subcategory_options(@asset.category)
      @categories = category_options
      render :form
    end

    def create
      @asset = Investments::Asset.new(asset_params)
      @categories = category_options
      @subcategories = form_subcategory_options(@asset.category)
      apply_lookup_metadata(@asset)
      @subcategories = form_subcategory_options(@asset.category)
      return render(:form, status: :unprocessable_entity) if @asset.errors.any?

      if @asset.save
        redirect_to edit_investments_asset_path(@asset), notice: t(".created")
      else
        render :form, status: :unprocessable_entity
      end
    end

    def edit
      @categories = category_options
      @subcategories = form_subcategory_options(@asset.category)
      render :form
    end

    def update
      @categories = category_options
      @subcategories = form_subcategory_options(asset_params[:category].presence || @asset.category)
      if @asset.update(asset_params)
        redirect_to edit_investments_asset_path(@asset), notice: t(".updated")
      else
        render :form, status: :unprocessable_entity
      end
    end

    private

    def asset_params
      params.require(:investments_asset).permit(:name, :symbol, :category, :subcategory, :currency, :active)
    end

    def apply_lookup_metadata(asset)
      return unless lookup_only_submission?(asset)

      asset_data = MarketData::AssetLookupService.new.call(symbol: asset.symbol)

      asset.name = asset_data.name
      asset.category = asset_data.category if asset_data.category.present?
      asset.subcategory = asset_data.subcategory if asset_data.subcategory.present?
      asset.currency = asset_data.currency
      asset.active = asset_data.active
    rescue MarketData::NotFoundError
      asset.errors.add(:symbol, "não foi encontrado no provedor de mercado")
      preserve_lookup_only_defaults(asset)
    rescue MarketData::ProviderError, MarketData::ConfigurationError => e
      asset.errors.add(:base, "Nao foi possivel buscar os dados do ativo: #{e.message}")
      preserve_lookup_only_defaults(asset)
    end

    def set_asset
      @asset = Investments::Asset.find(params[:id])
    end

    def lookup_only_submission?(asset)
      asset.symbol.present? &&
        asset.name.blank? &&
        asset.category.blank? &&
        asset.currency.blank? &&
        asset.subcategory.blank?
    end

    def preserve_lookup_only_defaults(asset)
      asset.active = true if asset.active.nil?
    end

    def category_options
      Investments::Asset.categories.keys.map do |key|
        [
          I18n.t("activerecord.attributes.investments/asset.categories.#{key}"),
          key
        ]
      end
    end

    def subcategory_options
      Investments::Asset.subcategories.keys.map do |key|
        [
          I18n.t("activerecord.attributes.investments/asset.subcategories.#{key}"),
          key
        ]
      end
    end

    def form_subcategory_options(category)
      Investments::Asset.allowed_subcategories_for(category).map do |key|
        [
          I18n.t("activerecord.attributes.investments/asset.subcategories.#{key}"),
          key
        ]
      end
    end

    def permitted_category(value)
      return if value.blank?
      return value if Investments::Asset.categories.key?(value)

      nil
    end

    def permitted_subcategory(value)
      return if value.blank?
      return value if Investments::Asset.subcategories.key?(value)

      nil
    end

    def build_asset_prices(assets)
      price_lookup_service = MarketData::PriceLookupService.new

      assets.each_with_object({}) do |asset, prices|
        prices[asset.id] = fetch_price_for(price_lookup_service, asset.symbol)
      end
    end

    def fetch_price_for(price_lookup_service, symbol)
      price_lookup_service.call(symbol: symbol)
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      nil
    end
  end
end
