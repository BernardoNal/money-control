# Issue 127 Implementation Plan

## Objective

Prevent duplicate imported transactions by using stable source identifiers when available and a documented fallback comparison when they are not.

## Scope

- Extend CSV normalization to recognize stable identifiers such as `Identificador`.
- Persist the identifier on imported transactions within the account boundary.
- Distinguish confirmed duplicates from possible matches in the import draft and preview.
- Preserve user review and explicit selection before confirmation.
- Add parser and request coverage for repeated files, repeated rows and fallback matching.

## Technical Strategy

1. Keep stable source identifiers separately from bank document numbers.
2. Match a non-blank source identifier exactly within the selected account.
3. For rows without an identifier, compare the account-scoped fingerprint built from date, amount, description, counterparty, payment method and document number.
4. Mark identifier matches as confirmed duplicates and fallback matches as possible duplicates.
5. Leave duplicate candidates unselected by default and expose the reason in the preview.
6. Keep account ownership enforced through the authenticated user's account association.

## Data Impact

- Add a nullable `source_identifier` column and account-scoped index to `transactions`.
- Existing manual and imported transactions remain compatible because the field is nullable.
- Existing fingerprint metadata continues to support formats without stable identifiers.

## Risks

- A source identifier may be unique only within a bank account, so matching remains account-scoped.
- Fallback matching can be ambiguous; it is advisory and never silently discards a row.
- Existing imports without the new field continue using the previous fingerprint behavior.

## Required Tests

- Parser recognition of `Identificador`.
- Repeated stable identifiers across files and within one file.
- Fallback possible duplicates without an identifier.
- Preview labels and default selection for both duplicate types.
- Account isolation for identifier matching.

## Approval

- status: approved
- approved by: user
