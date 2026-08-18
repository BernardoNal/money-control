class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]

  def index
    @accounts = policy_scope(Account)
  end

  def show
  end

  def new
    @account = Account.new
    authorize @account
    render :form
  end

  def create
    @account = Account.new(account_params)
    @account.user = current_user
    authorize @account

    if @account.save
      redirect_to account_path(@account), notice: "Conta criada com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    if @account.update(account_params)
      redirect_to account_path(@account), notice: "Conta alterada com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy

    redirect_to accounts_path, notice: "Conta excluida com sucesso."
  end

  private

  # Permits account parameters
  def account_params
    params.require(:account).permit(:name, :card_type, :bank, :initial_balance, :limit, :last_digits, :due_day)
  end

  def set_account
    @account = Account.find(params[:id])
    authorize @account
  end

end
