# Issue 37 Implementation Plan

## Objective

Implement the base `Investments::Income` model to track investment income events associated with user portfolios and global assets.

Supported income types:

- dividends
- JCP
- stock lending
- FII income
- amortization
- staking

## Affected Files

- `app/models/investments/income.rb`
- `app/models/investments/portfolio.rb`
- `app/models/investments/asset.rb`
- `db/migrate/*_create_investments_incomes.rb`
- `db/schema.rb`
- `spec/models/investments/income_spec.rb`
- `docs/code-overview.md`

## Risks

- Choosing an enum surface that may collide with framework methods
- Missing ownership clarity where the asset is global but the income belongs to a portfolio
- Forgetting financial consistency between gross, net, and tax amounts

## Technical Strategy

Implement `Investments::Income` as a namespaced model linked to:

- `Investments::Portfolio` as the user-owned receiving context
- `Investments::Asset` as the global asset reference

Use an enum for `income_type`, with a safe method prefix.

Add only the approved baseline validations in this issue, deferring stricter business rules to future work.

## Database Impact

Adds a new `investments_incomes` table with:

- `portfolio_id`
- `asset_id`
- `income_type`
- `gross_amount`
- `net_amount`
- `tax_amount`
- `payment_date`
- `reference_date`
- `notes`
- timestamps

Expected constraints:

- foreign keys to portfolios and assets
- non-null required fields
- non-null `tax_amount` with default `0`
- indexes for portfolio, asset, and payment date lookup

## Required Tests

- model specs for associations
- enum behavior coverage
- presence validations
- numeric validations
- financial consistency between gross and net amounts

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-25
