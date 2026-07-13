# Issue 73 Implementation Plan

## Objective

Allow users to create investment assets by entering only the ticker and automatically filling the remaining asset information through the market data provider abstraction.

## Affected Files

- `app/controllers/investments/assets_controller.rb`
- `app/views/investments/assets/form.html.erb`
- `spec/requests/investments/assets_spec.rb`
- `docs/governance/issue-73-implementation-plan.md`

## Risks

- Breaking the existing manual asset creation flow while introducing autofill
- Persisting partially filled records when lookup fails
- Creating controller logic that couples too directly to provider details instead of the lookup service

## Technical Strategy

Keep the current manual flow compatible, but when the submitted asset only contains a ticker, attempt an asset lookup through `MarketData::AssetLookupService`.

If lookup succeeds, fill:

- name
- category
- currency
- active

Keep subcategory optional when the provider does not return one.

If lookup fails, add a validation-style error to the form and keep the user on the creation screen.

## Database Impact

No database changes are required for this issue.

The work is limited to controller/form behavior and request coverage.

## Required Tests

- request spec for successful autofill from ticker
- request spec for invalid ticker lookup failure
- request spec proving manual asset creation still works

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-12
