# Issue 104 Implementation Plan

## Objective

Improve asset selection in investment forms so large asset catalogs are searched remotely and only a small result set is loaded at a time.

## Affected Files

- `app/controllers/investments/assets_controller.rb`
- `app/controllers/investments/transactions_controller.rb`
- `app/controllers/investments/incomes_controller.rb`
- `config/routes.rb`
- `app/components/investments/searchable_select_component.rb`
- `app/components/investments/searchable_select_component.html.erb`
- investment form views
- `app/javascript/application.js`
- request specs for the asset search endpoint and affected forms
- `docs/governance/issue-104-implementation-plan.md`

## Risks

- Losing the selected asset when editing or when validation fails
- Returning inactive assets in transaction flows that currently show only active assets
- Introducing an unscoped or unauthenticated search endpoint
- Excessive requests while typing or an inaccessible custom selector
- Changing existing asset selection semantics for incomes and transactions

## Technical Strategy

1. Add an authenticated asset search endpoint with normalized query input and a strict result limit.
2. Search the global asset catalog by symbol and name, ordered deterministically.
3. Preserve the current active-asset behavior for transaction forms through an explicit scope parameter.
4. Replace the full asset collections in transaction and income forms with a reusable search selector backed by a hidden `asset_id` field.
5. Render the current asset as the initial selected option and preserve it after validation errors.
6. Add debounced client-side requests, keyboard-friendly result selection and an empty/loading state without requiring a new frontend dependency.
7. Keep server-side ownership and record validation unchanged; the endpoint exposes only global asset metadata and remains behind authentication.

## Architecture, Security and Performance Impact

- Architecture: keeps catalog querying in the investments assets controller and selector behavior in a shared view/frontend component.
- Security: requires authentication and limits results to the global asset catalog; submitted IDs remain validated by existing controllers/models.
- Performance: avoids loading the full catalog and caps each response; a symbol/name prefix search and deterministic limit reduce database and network work.
- Compatibility: preserves existing form parameter names and selected values.

## Database Impact

No migration is expected initially. Existing indexes and bounded prefix search will be evaluated; a focused index can be added only if query analysis shows it is necessary.

## Required Tests

- Request specs for authenticated asset search, empty query, result limit and active-only behavior.
- Request specs confirming transaction and income forms preserve selected asset values.
- Regression specs for creating and updating transactions/incomes.
- JavaScript or system-level validation for selection, loading, empty and keyboard states where the project test setup supports it.
- `bundle exec rspec`, route validation and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-24
