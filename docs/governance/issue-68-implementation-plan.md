# Issue 68 Implementation Plan

## Objective

Improve dashboard usability by allowing users to filter analytics data on the portfolio dashboard.

The first iteration will support:

- portfolio context through the current portfolio show page
- date range filtering
- asset category filtering

## Affected Files

- `app/controllers/investments/portfolios_controller.rb`
- `app/services/investments/portfolio_dashboard_builder.rb`
- `app/views/investments/portfolios/show.html.erb`
- `spec/services/investments/portfolio_dashboard_builder_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`
- `docs/code-overview.md`

## Risks

- Applying filters inconsistently across summary cards, allocations, positions, and historical evolution
- Accidentally filtering the wrong dataset, especially mixing transaction dates with current open positions
- Breaking dashboard navigation by losing filter state between requests
- Adding controller logic that becomes too coupled to dashboard calculation details

## Technical Strategy

Introduce an explicit dashboard filter object at the controller boundary and pass normalized filter values into `Investments::PortfolioDashboardBuilder`.

Planned filters:

- `from_date`
- `to_date`
- `category`

Filtering behavior:

- transactions used for historical evolution, current positions, and recent activity should respect the selected date range
- asset/category summaries should only reflect the filtered transaction universe
- category filtering should limit dashboard calculations to assets in the selected category
- income summaries should be aligned with the selected date range and category whenever possible

The UI should:

- expose a compact filter form at the top of the dashboard
- preserve filter state in the query string
- allow users to clear filters easily

## Database Impact

No schema changes are required.

The implementation should rely on scoped queries over existing portfolios, transactions, incomes, and assets.

## Required Tests

- service specs covering date range filtering
- service specs covering category filtering
- service specs proving filtered summaries remain internally consistent
- request specs covering dashboard rendering with filters applied
- request specs proving filter state is preserved in navigation

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-16
