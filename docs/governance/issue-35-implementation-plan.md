# Issue 35 Implementation Plan

## Objective

Create the base `Investments::Asset` model as a global catalog entity for investment assets.

The model should support immutable or near-immutable market identifiers and classifications such as stocks, FIIs, ETFs, crypto, fixed income, and international assets.

## Affected Files

- `app/models/investments/asset.rb`
- `db/migrate/*_create_investments_assets.rb`
- `db/schema.rb`
- `spec/models/investments/asset_spec.rb`
- `docs/code-overview.md`

## Risks

- Choosing the wrong ownership model for assets
- Creating a category structure that is hard to evolve later
- Missing database constraints for fields that should behave like catalog identifiers

## Technical Strategy

Implement `Investments::Asset` as a namespaced Active Record model under the `Investments` domain.

Treat assets as a global catalog instead of a user-owned resource, because identifiers and categories should follow market definitions rather than per-user customization.

Use an enum for `category` and store a simple `currency` code plus an `active` flag.

Add model validations for required attributes and uniqueness for `symbol`.

## Database Impact

Adds a new `investments_assets` table with:

- `name`
- `symbol`
- `category`
- `currency`
- `active`
- timestamps

Expected constraints:

- `symbol` unique index
- `active` non-null with default `true`
- required catalog fields as non-null where appropriate

## Required Tests

- model specs for required attributes
- enum behavior coverage
- symbol uniqueness validation
- active default validation

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-21
