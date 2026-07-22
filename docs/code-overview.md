# Code Overview

This document is intentionally short.

Its goal is to help contributors understand where the main responsibilities live and where lightweight documentation matters most.

## Current Domain Areas

- `app/models/account.rb`
  financial accounts used by transactions
- `app/models/category.rb`
  transaction categorization, including global and user categories
- `app/models/transaction.rb`
  money movement records linked to accounts and categories
- `app/models/investments/portfolio.rb`
  base structure for investment portfolios owned by a user
- `app/models/investments/asset.rb`
  global catalog of market assets used as a base for future investment features
- `app/models/investments/transaction.rb`
  operation history connecting user portfolios to global investment assets
- `app/models/investments/income.rb`
  income history linked to a portfolio context and the asset that generated the payment
- `lib/market_data/*`
  provider abstraction and normalized service boundary for future external market data integrations
- `app/services/market_data/asset_lookup_service.rb`
  application-facing entrypoint for asset lookup so controllers and future flows do not call providers directly
- `app/services/market_data/price_lookup_service.rb`
  application-facing entrypoint for latest price retrieval so dashboard flows can consume market prices without depending on provider details
- `lib/market_data/providers/brapi_provider.rb`
  first concrete provider implementation with Brazil-first asset metadata lookup and latest price retrieval
- `app/services/investments/portfolio_dashboard_builder.rb`
  central aggregation service for portfolio analytics, including cost-based history and current market-value summaries

## Authentication And User Scope

- authentication is enforced in `ApplicationController`
- new features should prefer `current_user` scoping in controllers
- avoid unscoped `Model.all` and unrestricted `find(params[:id])` in user-owned resources

## Routing And UI

- resource CRUD follows Rails controllers and ERB views
- shared navigation lives in `app/views/shared/_navbar.html.erb`
- new modules should be added to navigation only when they are already usable
- primary action buttons should prefer the project navy tone `#000080`, with a slightly darker hover state, unless a specific flow requires a semantic color such as danger red
- reusable buttons should prefer `ButtonComponent`; for soft return and secondary navigation actions, use the olive variant instead of repeating inline utility strings

## Database Conventions

- prefer explicit foreign keys for user-owned data
- add indexes for lookup and uniqueness rules that matter to the domain
- do not modify old migrations; create new ones instead

## Local Configuration

- development-only secrets may live in a local `.env` file, which is already ignored by git
- keep a versioned `.env.example` with the variable names required to run integrations locally

## Tests

- model specs should cover validations and essential association behavior
- request specs should cover authenticated flows, user scoping, and invalid updates
- add broader system coverage only when the feature has meaningful UI behavior to validate

## Code Comments

Keep comments small and intentional.

Good places for comments:

- user scoping rules
- architectural expansion points such as namespaces
- non-obvious business rules

Avoid comments that only restate the code.
