# Issue 75 Implementation Plan

## Objective

Implement the first concrete market data provider using the existing provider abstraction so the application can retrieve asset metadata through a real external integration.

## Affected Files

- `lib/market_data/providers/brapi_provider.rb`
- `app/services/market_data/asset_lookup_service.rb`
- `docs/code-overview.md`
- `spec/lib/market_data/providers/brapi_provider_spec.rb`
- `spec/services/market_data/asset_lookup_service_spec.rb`

## Risks

- Coupling the application to provider-specific response shapes instead of normalizing data at the boundary
- Introducing brittle HTTP behavior or unclear errors when the provider returns incomplete or unauthorized responses
- Using category mapping heuristics that are too aggressive for incomplete metadata

## Technical Strategy

Implement a first concrete provider under `MarketData::Providers` using BRAPI's documented stock quote endpoint.

The provider will:

- fetch asset metadata by symbol
- normalize the response into `MarketData::AssetData`
- translate provider failures into `MarketData` error types
- map category only when a safe heuristic is available for the returned quote type

Integrate this provider into `MarketData::AssetLookupService` as the default provider so future application flows automatically use a Brazil-first integration point.

## Database Impact

No database changes are required for this issue.

The work is limited to service-layer integration with an external provider.

## Required Tests

- provider specs for successful lookup
- provider specs for missing symbol / provider error handling
- asset lookup service specs confirming the default provider integration

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-09
