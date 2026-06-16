# Issue 64 Implementation Plan

## Objective

Add a portfolio dashboard view that summarizes asset allocation by subcategory based on the current invested positions of the portfolio.

## Affected Files

- `app/services/investments/portfolio_dashboard_builder.rb`
- `app/views/investments/portfolios/show.html.erb`
- `spec/services/investments/portfolio_dashboard_builder_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`

## Risks

- Hiding invested capital from assets without a defined subcategory
- Duplicating subcategory aggregation logic in the view instead of keeping it in the dashboard builder
- Rendering subcategory labels inconsistently with the existing asset translations

## Technical Strategy

Extend the portfolio dashboard builder to expose a subcategory-level allocation summary derived from the current asset entries.

Group asset entries by `asset.subcategory`, sum invested capital for each group, and calculate the percentage over the portfolio `total_invested_amount`.

Assets without a defined subcategory must remain visible under a `Sem subcategoria` bucket so the dashboard reflects the full invested amount.

Render a compact dashboard section for subcategory allocation following the existing portfolio dashboard visual language.

## Database Impact

No database changes are required for this issue.

The existing asset subcategory enum and portfolio transaction data already support the feature.

## Required Tests

- service specs for subcategory aggregation totals and percentages
- request specs for dashboard rendering with allocation by subcategory
- empty-state validation for portfolios without positions

## Approval

- status: approved
- approved by: user
- approval date: 2026-06-16
