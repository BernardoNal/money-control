# Issue 117 Implementation Plan

## Objective

Make market price lookup compatible with the free BRAPI plan while keeping the maximum batch size configurable for future plan upgrades.

## Affected Files

- `lib/market_data/providers/brapi_provider.rb`
- `spec/lib/market_data/providers/brapi_provider_spec.rb`
- `app/services/market_data/price_lookup_service.rb` if service-level behavior requires coverage
- `spec/services/market_data/price_lookup_service_spec.rb` if service-level behavior requires coverage
- `.env.example` or relevant local configuration documentation
- `docs/governance/issue-117-implementation-plan.md`

## Risks

- Sending more symbols than the configured provider plan allows
- Treating an invalid or non-positive configuration as a valid batch size
- Losing valid prices when one batch is incomplete or unavailable
- Increasing request count for free-plan users and triggering provider rate limits
- Exposing provider credentials while documenting configuration

## Technical Strategy

1. Add a provider-level maximum symbols per request configuration with environment variable `BRAPI_MAX_SYMBOLS_PER_REQUEST`.
2. Use a safe default of 1 to support the free BRAPI plan.
3. Normalize and deduplicate symbols before splitting them into bounded batches.
4. Request each batch through the existing HTTP abstraction and combine normalized `PriceData` results.
5. Preserve single-symbol `fetch_price` behavior and existing missing-price fallback.
6. Validate positive configuration values and fail clearly during provider initialization or lookup.
7. Document the variable name and default without exposing any API token.

## Checkpoints

1. Provider configuration and bounded batch splitting, with unit specs.
2. Partial-result handling, service integration and configuration documentation.
3. Full validation, security review and delivery preparation.

## Architecture, Security and Performance Impact

- Architecture: keeps provider-plan details inside the BRAPI adapter; dashboard and application services keep their existing contract.
- Security: documents only the configuration name and never logs or exposes the token.
- Performance: free-plan mode increases calls predictably; upgraded plans can reduce calls by increasing the limit.
- Compatibility: single-symbol calls and cost-basis fallback remain supported.

## Database Impact

No migration or schema change is expected.

## Required Tests

- Provider specs for default limit, configured limit and invalid values.
- Provider specs asserting no request exceeds the configured limit.
- Specs combining results across multiple batches.
- Specs preserving valid results when another symbol has no price.
- Existing service, dashboard and full RSpec suite.
- Route validation and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-28
