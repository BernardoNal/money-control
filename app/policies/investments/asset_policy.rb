module Investments
  class AssetPolicy < ApplicationPolicy
    # Only administrators may add records to the shared asset catalog.
    def create?
      user.admin?
    end

    # Only administrators may change records in the shared asset catalog.
    def update?
      user.admin?
    end
  end
end
