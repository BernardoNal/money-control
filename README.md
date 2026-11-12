# Money Control

[English](README.md) | [Português](README.pt-BR.md)

Money Control is a Ruby on Rails application for organizing personal finances. It brings accounts, transactions, categories, investment portfolios, market assets, investment transactions, and income records into one authenticated application.

## Current capabilities

- Manage financial accounts and account balances.
- Create, edit, filter, and import transactions from CSV files.
- Category organization is currently under analysis and testing; its continuation will be evaluated before being treated as a stable capability.
- Manage investment portfolios and positions.
- Track investment transactions and income records.
- Import investment income from XLSX files with manual review and duplicate checks.
- View portfolio performance, market values, income analytics, and tax reports.
- Hide sensitive financial values with the global privacy control.
- Generate administrator-only PostgreSQL backups.

For a map of the domain responsibilities, see [the code overview](docs/code-overview.md).

## Requirements

- Ruby 3.2.6 (see `.ruby-version`).
- PostgreSQL, with PostgreSQL 16 used by the CI environment.
- Bundler.
- Node.js is not required for the normal development workflow; JavaScript uses Rails import maps.
- `pg_dump` and `pg_restore` are required for database backup and restore operations.

## Local setup

1. Clone the repository and enter the project directory.
2. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

3. Add local integration values to `.env` when needed. Never commit `.env` or real credentials.
4. Run the idempotent setup script:

   ```bash
   bin/setup
   ```

`bin/setup` installs dependencies, prepares the database, clears local logs and temporary files, and restarts the Rails application.

## Running locally

To run Rails and the Tailwind watcher together:

```bash
bin/dev
```

To run only the Rails server:

```bash
bin/rails server
```

The application is available at [http://localhost:3000](http://localhost:3000) by default.

To build the stylesheet once:

```bash
bin/rails tailwindcss:build
```

## Environment variables

The versioned [.env.example](.env.example) documents the supported local variables:

- `BRAPI_API_TOKEN`: optional token for market data lookups.
- `BRAPI_MAX_SYMBOLS_PER_REQUEST`: maximum number of symbols requested per provider call.

Database connection values should be provided through Rails database configuration or `DATABASE_URL` in the environment. Do not place production credentials in tracked files.

## Tests and CI

Run the complete test suite with:

```bash
bundle exec rspec
```

The CI workflow also builds Tailwind and loads the test schema before running RSpec. See [the CI workflow](.github/workflows/ci.yml) for the exact pipeline.

Useful targeted commands include:

```bash
bundle exec rspec spec/requests
bundle exec rspec spec/services
git diff --check
```

## Project structure

- `app/models`: persistence and domain associations.
- `app/controllers`: authenticated request handling and user-scoped flows.
- `app/services`: business rules, analytics, imports, reports, and external integration boundaries.
- `app/policies`: authorization rules for protected resources.
- `app/views`: Rails ERB views and shared navigation.
- `app/components`: reusable ViewComponent UI elements.
- `lib/market_data`: market provider contracts and implementations.
- `lib/tasks`: custom Rails tasks, including operational database commands.
- `spec`: model, request, policy, service, helper, and component tests.
- `docs`: governance, architecture, and operational documentation.

## Security and data handling

- Authentication is enforced by `ApplicationController`.
- User-owned records must remain scoped to the authenticated user.
- Backups contain sensitive user and financial data.
- Only administrators can generate application database backups.
- Keep `.env`, downloaded backup files, and production credentials outside version control.
- Database restore is an administrative or deployment operation and can replace existing database objects. Read the operational guide and take a separate backup before restoring.

See [Database backup and restore](docs/operations/database-backup-restore.md) for the complete procedure.

## Architecture and governance

- [Code overview](docs/code-overview.md)
- [Development workflow](docs/governance/development-workflow.md)
- [Governance documentation](docs/governance/README.en.md)

All changes should use a dedicated branch, follow the documented approval boundaries, preserve user-data isolation, and include proportional validation. Commit, push, and pull request approvals are separate actions.
