class AccountPolicy < ApplicationPolicy
  def create?
    true
  end

  def new?
    create?
  end
  def show?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  private

  def owner?
    record.user == user
  end
end
