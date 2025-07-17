class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]
  def index
    @accounts = Account.all
  end

  def show
  end

  def new
    @account = Account.new
    render :form
  end

  def create
    # @user = current_user
     @user = User.first
    @account = Account.new(account_params)
    @account.user = @user
    if @account.save
      redirect_to account_path(@account)
      flash[:alert] = "Conta criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
     render :form
  end

  def update
    # @user = current_user
     @user = User.first
    @account = Account.new(account_params)
    @account.user = @user
    if @account.save
      redirect_to account_path(@account)
      flash[:alert] = "Conta alterada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    flash[:alert] = "Conta excluída com sucesso."

    redirect_to accounts_path()
  end

  private

  # Permits account parameters
  def account_params
    params.require(:account).permit( :name, :card_type, :bank, :initial_balance, :limit, :last_digits,:due_day)
  end

  def set_account
    @account = Account.find(params[:id])
  end
end
