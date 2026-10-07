# Issue 65 Implementation Plan

## Objective

Add an income analytics overview to the existing Proventos area while preserving the current filtered and paginated income list.

## Affected Files

- `app/services/investments/income_analytics_builder.rb`
- `app/controllers/investments/incomes_controller.rb`
- `app/views/investments/incomes/index.html.erb`
- `app/javascript/application.js`
- `spec/services/investments/income_analytics_builder_spec.rb`
- `spec/requests/investments/incomes_spec.rb`

## Risks

- Aggregations must remain scoped to incomes belonging to portfolios owned by the authenticated user.
- The existing list filters and pagination must continue to work when switching sections.
- Analytics should not introduce N+1 queries or duplicate income domain logic.
- The overview must use received net amounts consistently with the existing portfolio passive-income summary.

## Technical Strategy

Build analytics from the already filtered and policy-scoped `Investments::Income` relation.

Expose a small result object with total net income, totals grouped by enum type, and record count. Keep this calculation outside the controller and model so it can grow to support future history charts.

Add Overview and List navigation following the existing portfolio tab pattern, with Overview as the initial section and the current list behavior preserved under List.

## Database Impact

No migration or schema change. Existing `payment_date`, `portfolio_id`, and `income_type` fields support the required aggregation.

## Required Tests

- service specs for totals, grouping, empty data, and net amount calculation
- request specs for authenticated overview data, filters, user isolation, tab switching, and unchanged list behavior
- full regression suite and route/template validation

## Checkpoints

1. Analytics service, controller integration, and calculation specs.
2. Overview/List navigation and UI, with request coverage.
3. Final review, full validation, commit, and pull request.

## Approval

- status: approved
- approved by: user
- approval date: 2026-10-06
