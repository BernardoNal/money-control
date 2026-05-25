# Issue 36 Implementation Plan

## Objective

Implement the base `Investments::Transaction` model to represent investment operation history between user portfolios and global assets.

Supported operations:

- buy
- sell
- transfer
- split
- reverse split

## Affected Files

- `app/models/investments/transaction.rb`
- `app/models/investments/portfolio.rb`
- `app/models/investments/asset.rb`
- `db/migrate/*_create_investments_transactions.rb`
- `db/schema.rb`
- `spec/models/investments/transaction_spec.rb`
- `docs/code-overview.md`

## Risks

- Modeling price rules too strictly or too loosely for different transaction types
- Forgetting ownership boundaries where transactions belong to user portfolios but assets are global
- Missing indexes for historical lookup by portfolio, asset, or date

## Technical Strategy

Implement `Investments::Transaction` as a namespaced model linked to:

- `Investments::Portfolio` as a user-owned container
- `Investments::Asset` as a global catalog record

Use an enum for `transaction_type`.

Add validations for required data, quantity, fees, and conditional price presence for market trades.

Keep the scope at the model/database layer for this issue, without introducing CRUD yet.

## Database Impact

Adds a new `investments_transactions` table with:

- `portfolio_id`
- `asset_id`
- `transaction_type`
- `quantity`
- `price`
- `fees`
- `date`
- `notes`
- timestamps

Expected constraints:

- foreign keys to portfolios and assets
- required fields as non-null where appropriate
- indexes for portfolio, asset, and date lookups

## Required Tests

- model specs for associations
- enum behavior coverage
- presence validations
- numeric validations
- conditional price validation by transaction type

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-24
