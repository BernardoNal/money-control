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

## Authentication And User Scope

- authentication is enforced in `ApplicationController`
- new features should prefer `current_user` scoping in controllers
- avoid unscoped `Model.all` and unrestricted `find(params[:id])` in user-owned resources

## Routing And UI

- resource CRUD follows Rails controllers and ERB views
- shared navigation lives in `app/views/shared/_navbar.html.erb`
- new modules should be added to navigation only when they are already usable

## Database Conventions

- prefer explicit foreign keys for user-owned data
- add indexes for lookup and uniqueness rules that matter to the domain
- do not modify old migrations; create new ones instead

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
