# Issue 34 Implementation Plan

## Objective

Create the base structure for investment portfolios through the `Investments::Portfolio` model, associating portfolios with `User`, exposing an initial CRUD flow, and adding validations and automated tests.

## Affected Files

- `app/models/user.rb`
- `app/models/investments/portfolio.rb`
- `app/controllers/investments/portfolios_controller.rb`
- `app/views/investments/portfolios/*`
- `config/routes.rb`
- `app/views/shared/_navbar.html.erb`
- `db/migrate/20260521000000_create_investments_portfolios.rb`
- `db/schema.rb`
- `spec/models/investments/portfolio_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`

## Risks

- Repeating existing multi-user scoping problems already present in other CRUDs.
- Creating routes or parameter naming inconsistencies due to the `Investments` namespace.
- Missing database constraints, which would allow duplicate portfolio names for the same user.
- Adding UI entry points without verifying route integrity.

## Technical Strategy

Implement a namespaced model, `Investments::Portfolio`, backed by the `investments_portfolios` table.

Associate portfolios to `User` through `has_many` and `belongs_to`.

Expose a namespaced controller and basic views for `index`, `show`, `new`, `create`, `edit`, `update`, and `destroy`.

Scope all reads and writes to `current_user` in the new controller so the module does not inherit the unscoped behavior currently present elsewhere in the application.

Add navigation access through the shared navbar.

## Database Impact

Adds a new table, `investments_portfolios`, with:

- `name` as required field
- `user_id` as non-null foreign key
- timestamps
- unique index on `[:user_id, :name]`

This introduces a new migration and updates `db/schema.rb`.

## Required Tests

- model specs for validations and associations behavior
- request specs for create, index scoping, update, and destroy
- route sanity validation through Rails routes inspection

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-21
