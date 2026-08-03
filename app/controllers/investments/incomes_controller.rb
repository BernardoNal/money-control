class Investments::IncomesController < ApplicationController
  before_action :set_income, only: %i[show edit update]
  before_action :load_form_collections, only: %i[index new create edit update destroy]

  def index
    @total_incomes = 10
    @offset = params[:set].to_i % @total_incomes == 0 ? params[:set].to_i : 0

    @selected_income_type = permitted_income_type(params[:income_type])
    @selected_asset = permitted_asset(params[:asset])
    @selected_portfolio = permitted_asset(params[:portfolio])
    @incomes = Investments::Income.includes(:asset, :portfolio)
    @incomes = @incomes.where(income_type: @selected_income_type) if @selected_income_type.present?
    @incomes = @incomes.where(asset: @selected_asset) if @selected_asset.present?
    @incomes = @incomes.where(portfolio: @selected_portfolio) if @selected_portfolio.present?
    @visible_incomes = @incomes.limit(@total_incomes).offset(@offset)
  end

  def show
  end

  def new
    @income = Investments::Income.new
    render :form
  end

  def create
    @income = Investments::Income.new(income_params)

    if @income.save
      redirect_to investments_income_path(@income),
                  notice: "Provento criado com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    if @income.update(income_params)
      redirect_to investments_income_path(@income),
                  notice: "Provento atualizado com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    @income.destroy

    redirect_to investments_incomes_path,
                notice: "Provento removido com sucesso."
  end

  private

  def set_income
    @income = Investments::Income.find(params[:id])
  end

  def income_params
    params.require(:investments_income).permit(
      :portfolio_id,
      :asset_id,
      :income_type,
      :gross_amount,
      :net_amount,
      :tax_amount,
      :payment_date,
      :reference_date,
      :notes
    )
  end

  def load_form_collections
    @portfolios = Investments::Portfolio.where(user: current_user)
                                    .order(:name)
                                    .map { |portfolio| [portfolio.name, portfolio.id] }

    @assets = Investments::Asset.order(:symbol)
                                .map { |a| ["#{a.symbol} - #{a.name.first(20)}", a.id] }

    @income_types = income_options
  end

  def income_options
    Investments::Income.income_types.keys.map do |key|
      [
        I18n.t(
          "activerecord.attributes.investments/income.income_types.#{key}",
          default: key.humanize
        ),
        key
      ]
    end
  end

  def permitted_income_type(value)
    return if value.blank?
    return value if Investments::Income.income_types.key?(value)

    nil
  end

  def permitted_asset(value)
    return if value.blank?
    return value if Investments::Asset.exists?(id: value)

    nil
  end

  def permitted_income_type(value)
    return if value.blank?
    return value if Investments::Portfolio.where(user: current_user).key?(value)

    nil
  end
end
