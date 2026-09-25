# Issue 113 Implementation Plan

## Objective

Prevent users from reassigning financial records to accounts or portfolios owned by another user during update flows.

## Affected Files

- `app/controllers/transactions_controller.rb`
- `app/controllers/investments/transactions_controller.rb`
- `app/controllers/investments/incomes_controller.rb`
- request specs for regular transactions, investment transactions and investment incomes
- `docs/governance/issue-113-implementation-plan.md`

## Risks

- Rejecting legitimate updates when the destination belongs to the current user
- Leaving one update path with unrestricted foreign-key assignment
- Returning inconsistent responses when a destination record is invalid or belongs to another user
- Changing existing authorization behavior for records already owned by another user

## Technical Strategy

1. Keep authorization of the existing record through the current Pundit policies.
2. Validate destination ownership through `current_user`-scoped lookups before updating account or portfolio associations.
3. Avoid accepting unrestricted destination records from mass-assigned parameters.
4. Preserve the existing redirect and validation-error behavior for valid updates.
5. Return the existing safe redirect behavior when a destination account or portfolio is not owned by the current user.
6. Add request specs for valid reassignment within the same user and rejected cross-user reassignment.

## Checkpoints

1. Regular transaction account reassignment and request specs.
2. Investment transaction and income portfolio reassignment and request specs.
3. Full validation, security review and delivery preparation.

## Architecture, Security and Performance Impact

- Architecture: keeps ownership validation at the controller/service boundary while preserving existing policies.
- Security: prevents cross-user reassignment through forged update parameters.
- Performance: uses scoped primary-key lookups and does not add unbounded queries.
- Compatibility: valid updates for records owned by the current user continue to work.

## Database Impact

No migration or schema change is expected. Existing foreign keys remain unchanged.

## Required Tests

- Request specs for regular transactions with same-user and cross-user account updates.
- Request specs for investment transactions with same-user and cross-user portfolio updates.
- Request specs for investment incomes with same-user and cross-user portfolio updates.
- Regression coverage confirming the original record remains unchanged after rejected reassignment.
- `bundle exec rspec`, route validation and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-25
