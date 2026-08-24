class TransactionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:account)
        .where(accounts: { user_id: user.id })
    end
  end

  def show?
    record.account.user_id == user.id
  end

  def update?
    record.account.user_id == user.id
  end

  def destroy?
    record.account.user_id == user.id
  end
end
