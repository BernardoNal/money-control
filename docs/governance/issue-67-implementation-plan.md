# Issue 67 Implementation Plan

## Objective

Extend the portfolio dashboard to show both:

- historical portfolio evolution based on recorded investment transactions
- current portfolio market value based on the latest available asset prices

The implementation must keep those two calculations separated internally so historical cost evolution is not confused with current market valuation.

## Affected Files

- `app/services/investments/portfolio_dashboard_builder.rb`
- `app/views/investments/portfolios/show.html.erb`
- `app/services/market_data/asset_lookup_service.rb`
- `lib/market_data/providers/brapi_provider.rb`
- `spec/services/investments/portfolio_dashboard_builder_spec.rb`
- `spec/requests/investments/portfolios_spec.rb`
- `docs/code-overview.md`

## Risks

- Mixing historical transaction-based values with current market-price values in the same calculation
- Introducing dashboard failures when price data is unavailable for some assets
- Coupling portfolio analytics too tightly to a specific market data provider
- Misleading users if partial market coverage is not communicated clearly

## Technical Strategy

Keep the dashboard builder as the orchestration point, but split the new analytics into two distinct outputs:

1. historical evolution series
   - derived only from recorded transactions
   - grouped by date
   - independent from external market data

2. current market valuation
   - derived from current portfolio positions
   - enriched with the latest available price for each asset
   - resilient when some assets do not have price coverage

The UI should make the distinction explicit:

- historical evolution chart = transaction-based
- current portfolio value = market-price-based

If market data is missing for an asset, the dashboard should continue rendering and expose a clear warning or fallback state instead of failing.

## Database Impact

No schema changes are planned for the first iteration.

The implementation should reuse the current assets, transactions and portfolio data model.

## Required Tests

- service specs for historical portfolio evolution calculations
- service specs for current market value calculations
- service specs for missing price coverage scenarios
- request specs covering the updated portfolio dashboard rendering
- manual validation for mixed portfolios with priced and unpriced assets

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-13
