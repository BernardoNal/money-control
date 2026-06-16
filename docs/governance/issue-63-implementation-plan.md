# Issue 63 Implementation Plan

## Objective

Add a portfolio dashboard view that summarizes asset allocation by category based on the current invested positions of the portfolio.

## Affected Files

- `app/services/investments/portfolio_dashboard_builder.rb`
- `app/views/investments/portfolios/show.html.erb`
- `spec/services/investments/portfolio_dashboard_builder_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`

## Risks

- Calculating allocation from raw transactions instead of current positions and producing inconsistent totals
- Duplicating aggregation logic in the view instead of centralizing it in the dashboard builder
- Rendering category labels inconsistently with the existing asset translations

## Technical Strategy

Extend the portfolio dashboard builder to expose a category-level allocation summary derived from the already computed asset entries.

Group asset entries by `asset.category`, sum each category invested amount, and calculate the percentage over the portfolio `total_invested_amount`.

Render a new dashboard section in the portfolio show page using the existing visual language and an empty state when there are no positions.

## Database Impact

No database changes are required for this issue.

The existing asset category enum and portfolio transaction data already support the feature.

## Required Tests

- service specs for category aggregation totals and percentages
- request specs for dashboard rendering with allocation by category
- empty-state validation for portfolios without positions

## Approval

- status: approved
- approved by: user
- approval date: 2026-06-16
