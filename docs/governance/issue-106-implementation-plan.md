# Issue 106 Implementation Plan

## Objective

Handle BDR metadata returned by the market data provider so asset names are user-friendly while preserving reliable ticker identification.

## Affected Files

- `lib/market_data/providers/brapi_provider.rb`
- `lib/market_data/asset_data.rb`, only if the provider contract needs a focused metadata field
- `spec/lib/market_data/providers/brapi_provider_spec.rb`
- `spec/services/market_data/asset_lookup_service_spec.rb`, only if the service contract is affected
- `spec/requests/investments/assets_spec.rb`
- `docs/governance/issue-106-implementation-plan.md`

## Risks

- Choosing a provider field that is incomplete or inconsistent across BDRs
- Introducing fragile string parsing or changing names for non-BDR assets
- Breaking existing asset creation behavior or ticker matching
- Increasing API calls while investigating provider data

## Technical Strategy

1. Inspect the current BRAPI payload contract and existing normalization tests.
2. Identify the explicit provider fields that distinguish BDRs and the most stable issuer/security name.
3. When no dedicated issuer field exists, extract only the issuer prefix before BRAPI's `Shs` marker for BDRs, with safe fallbacks.
4. Keep exact symbol matching and existing behavior for stocks, ETFs, FIIs and other asset types.
5. Add fixture-style unit examples for representative BDR payloads, including the long technical descriptions from the issue.
6. Validate the asset creation request flow and the complete relevant test suite.

## Architecture, Security and Performance Impact

- Architecture: keeps provider-specific interpretation inside `BrapiProvider`.
- Security: no new user input, authorization, or record ownership behavior.
- Performance: no additional API request; the response already fetched is normalized locally.
- Compatibility: non-BDR mappings remain unchanged.

## Database Impact

None. No migration or schema change is expected.

## Required Tests

- Brapi provider specs for BDR detection, naming and symbol preservation.
- Regression specs for existing stock and ETF mappings.
- Asset creation request spec using normalized BDR data.
- `bundle exec rspec` and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-23
