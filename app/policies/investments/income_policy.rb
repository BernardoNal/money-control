module Investments
  class IncomePolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        scope
          .joins(:portfolio)
          .where(investments_portfolios: { user_id: user.id })
      end
    end

    def show?
      record.portfolio.user_id == user.id
    end

    def update?
      record.portfolio.user_id == user.id
    end

    def destroy?
      record.portfolio.user_id == user.id
    end
  end
end
