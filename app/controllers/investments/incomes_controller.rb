class Investments::IncomesController < ApplicationController
  before_action :set_income, only: %i[show edit update]
  before_action :load_form_collections, only: %i[new create edit update destroy]

  def index
    @incomes = Investments::Income.includes(:asset, :portfolio)
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
    @portfolios = Investments::Portfolio.order(:name)
                                        .map { |p| [p.name, p.id] }

    @assets = Investments::Asset.order(:symbol)
                                .map { |a| ["#{a.symbol} - #{a.name}", a.id] }

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
end
