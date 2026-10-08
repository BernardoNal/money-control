# Issue 66 Implementation Plan

## Objective

Add a historical monthly income chart to the Proventos Overview using the existing income records and payment dates.

## Affected Files

- `app/services/investments/income_analytics_builder.rb`
- `app/views/investments/incomes/index.html.erb`
- `spec/services/investments/income_analytics_builder_spec.rb`
- `spec/requests/investments/incomes_spec.rb`
- `docs/governance/issue-66-implementation-plan.md`

## Risks

- Monthly totals must use `payment_date`, not creation timestamps.
- Aggregations must remain scoped to the authenticated user's portfolios.
- Months without receipts must be represented consistently so the trend is not misleading.
- The chart should remain readable when the all-time period spans many months.

## Technical Strategy

Extend `Investments::IncomeAnalyticsBuilder` with a monthly series of net income entries.

Aggregate daily database totals into month buckets, fill gaps with zero values, and use the selected Overview period as the chart range. The existing `Todo o período` option provides the complete historical view.

Render the series with the existing server-rendered CSS bar-chart pattern used by the portfolio dashboard, avoiding a new chart dependency.

## Database Impact

No migration or schema change. The existing payment date index supports the historical lookup.

## Required Tests

- service specs for monthly aggregation across multiple records
- service specs for zero-filled months and empty data
- request specs for chart rendering and empty state
- full regression suite and route/template validation

## Checkpoints

1. Monthly series in the analytics builder and calculation specs.
2. Historical chart UI and request coverage.
3. Final review, full validation, commit, and pull request.

## Approval

- status: approved
- approved by: user
- approval date: 2026-10-07
