class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new create edit update]
  before_action :set_accounts, only: %i[new create edit update]

  def index
    @transactions = policy_scope(Transaction).includes(:account, :category).order(date: :desc)
  end

  def show
  end

  def new
    @transaction = Transaction.new
    render :form
  end

  def create
    @transaction = Transaction.new(transaction_params)
    apply_other_payment_method

    set_transaction_account
    return if performed?

    if @transaction.save
      redirect_to transaction_path(@transaction), notice: t(".created")
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    set_transaction_account
    return if performed?
    apply_other_payment_method

    if @transaction.update(transaction_params.except(:account_id))
      redirect_to transaction_path(@transaction), notice: t(".updated")
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy

    redirect_to transactions_path,
                alert: t(".destroyed")
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :amount,
      :description,
      :to_whom,
      :payment_method,
      :date,
      :category_id,
      :account_id
    )
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
    authorize @transaction
  end

  def set_categories
    @categories = Category.for_user(current_user.id).order(:name)
  end

  def set_accounts
    @accounts = Account.where(user: current_user)
  end

  def set_transaction_account
    account_id = transaction_params[:account_id]
    return if @transaction.persisted? && account_id.blank?

    # Account changes must also respect user authorization, including when
    # the form attempts to submit a different account.
    # Scope destination accounts to the current user before changing ownership.
    @transaction.account = current_user.accounts.find(account_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def current_user_transactions
    Transaction.joins(:account).where(accounts: { user_id: current_user.id })
  end

  def apply_other_payment_method
    return unless @transaction.payment_method == "Outro"

    other_payment_method = params.dig(:transaction, :payment_method_other).to_s.strip
    @transaction.payment_method = other_payment_method.presence || "Outro"
  end
end
