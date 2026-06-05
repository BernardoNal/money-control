# Issue 40 Implementation Plan

## Objective

Create the initial investment portfolio dashboard with the metrics currently supported by the investments domain.

## Affected Files

- `app/controllers/investments/portfolios_controller.rb`
- `app/views/investments/portfolios/show.html.erb`
- `app/services/investments/portfolio_dashboard_builder.rb`
- `spec/services/investments/portfolio_dashboard_builder_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`

## Risks

- Dashboard fields may imply market pricing that does not exist yet
- Naive per-asset calculations could introduce N+1 queries
- Aggregating transactions and incomes incorrectly could produce misleading metrics

## Technical Strategy

Use the portfolio show page as the initial dashboard entry point.

Implement a dedicated service object to build dashboard data from:

- portfolio transactions
- portfolio incomes

Use a single transaction query and a single income query, grouped in memory by asset.

Because there is no current market quote source yet, populate:

- current portfolio value using current cost basis
- unrealized profit/loss as zero

The UI should make this approximation explicit.

## Database Impact

No database changes are required for this issue.

The dashboard is derived from existing portfolios, transactions, assets, and incomes.

## Required Tests

- service specs for aggregated dashboard metrics
- request spec to verify dashboard rendering
- request spec to verify user scoping on portfolio show/dashboard

## Approval

- status: approved
- approved by: user
- approval date: 2026-06-02
