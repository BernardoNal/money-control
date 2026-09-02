class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Pundit::Authorization

  # # Pundit: allow-list approach
  # after_action :verify_authorized, except: :index, unless: :skip_pundit?
  # after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def user_not_authorized
    flash[:alert] = "Você não tem autorização para acessar essa página."
    redirect_to(root_path)
  end

  private

  def record_not_found
    redirect_to(record_not_found_redirect_path, alert: "Registro não encontrado ou indisponivel.")
  end

  def record_not_found_redirect_path
    case controller_path
    when "accounts"
      accounts_path
    when "categories"
      categories_path
    when "transactions"
      transactions_path
    when "investments/assets"
      investments_assets_path
    when "investments/portfolios"
      investments_portfolios_path
    when "investments/incomes"
      investments_incomes_path
    when "investments/transactions"
      investments_transactions_path
    else
      root_path
    end
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :address, :cpf, :role])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :address, :cpf, :role])
  end
end
