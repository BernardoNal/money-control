class Investments::TransactionPolicy < ApplicationPolicy
  def show?
    record.portfolio.user_id == user.id
  end

  def update?
    record.portfolio.user_id == user.id
  end

  def destroy?
    record.portfolio.user_id == user.id
  end
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:portfolio)
        .where(investments_portfolios: { user_id: user.id })
    end
  end
end
