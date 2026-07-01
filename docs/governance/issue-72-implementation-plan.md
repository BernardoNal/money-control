# Issue 72 Implementation Plan

## Objective

Create a provider abstraction layer for external market data so the investments domain depends on a stable interface instead of a concrete implementation.

## Affected Files

- `lib/market_data/provider.rb`
- `lib/market_data/asset_data.rb`
- `lib/market_data/errors.rb`
- `lib/market_data/null_provider.rb`
- `app/services/market_data/asset_lookup_service.rb`
- `docs/code-overview.md`
- `spec/lib/market_data/provider_spec.rb`
- `spec/lib/market_data/null_provider_spec.rb`
- `spec/services/market_data/asset_lookup_service_spec.rb`

## Risks

- Over-designing the abstraction before the first provider exists
- Blurring the boundary between provider contract and application service responsibility
- Locking future provider integrations into an interface that is too narrow or too provider-specific

## Technical Strategy

Create a `MarketData` namespace with:

- a provider contract defining the expected operations
- a value object for normalized asset lookup results
- domain-specific error classes
- a null provider used when no real provider is configured yet

Add `MarketData::AssetLookupService` as the application-facing lookup entrypoint so future features use the service instead of calling providers directly.

This issue will not introduce any HTTP client or external integration.

## Database Impact

No database changes are required for this issue.

The work is limited to architecture and service-layer abstractions.

## Required Tests

- provider contract specs
- null provider specs
- asset lookup service specs with injected test doubles

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-01
