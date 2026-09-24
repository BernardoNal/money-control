# Issue 103 Implementation Plan

## Objective

Reduce redundant market API requests in investment flows without changing valuation behavior or introducing stale data.

## Affected Files

- `lib/market_data/provider.rb` and `lib/market_data/null_provider.rb`
- `lib/market_data/providers/brapi_provider.rb`
- `app/services/market_data/price_lookup_service.rb`
- `app/services/investments/portfolio_dashboard_builder.rb`
- relevant provider, service and dashboard specs
- `docs/governance/issue-103-implementation-plan.md`

## Risks

- Changing the provider contract without preserving single-symbol callers
- Losing a price or misaligning a returned quote with its requested symbol
- Treating partial batch responses as complete data
- Changing fallback behavior when a quote is unavailable
- Hiding rate-limit or provider errors while reducing request count

## Technical Strategy

1. Add a batch price lookup contract that accepts normalized symbols and returns normalized `PriceData` entries keyed by symbol.
2. Implement the batch request in `BrapiProvider` using the existing `/stocks/quote` endpoint with multiple symbols.
3. Keep `fetch_price` as a compatibility wrapper over the batch operation for existing callers.
4. Update `PortfolioDashboardBuilder` to request prices once for all current position assets instead of once per asset.
5. Preserve cost-basis fallback for missing or invalid individual quotes in a partial batch response.
6. Measure request behavior with provider doubles and regression specs for single and batch lookups.

## Checkpoints

1. Provider contract and batch normalization, with unit specs.
2. Dashboard integration and request-count regression specs.
3. Full validation and delivery review.

## Architecture, Security and Performance Impact

- Architecture: keeps batching inside the market data abstraction; dashboard logic does not depend on BRAPI response details.
- Security: no new endpoint or user input; portfolio data remains scoped through the existing dashboard queries.
- Performance: reduces N price calls per dashboard to one bounded batch call per dashboard build.
- Compatibility: single-symbol lookups and missing-price fallback remain supported.

## Database Impact

None. No migration or schema change is expected.

## Required Tests

- Provider specs for batch success, partial results and missing prices.
- Price lookup service specs for normalization and result indexing.
- Dashboard spec asserting one batch lookup for multiple assets.
- Existing request and full RSpec suite.
- `git diff --check` and route validation.

## Approval

- status: pending
- approved by: user
- approval date: 2026-09-24
