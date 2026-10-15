# Issue 123 Implementation Plan

## Objective

Add an annual investment income report for Brazilian income tax preparation. Users should select a reporting year, inspect income records grouped by asset and income type, review subgroup totals, and download the same report as a PDF.

## Affected Areas

- `Gemfile` and `Gemfile.lock` for the Prawn dependency.
- `config/routes.rb` for the report endpoint.
- `app/services/investments/income_tax_report_builder.rb` for user-scoped filtering, grouping, ordering and totals.
- `app/services/investments/income_tax_report_pdf.rb` for PDF rendering with Prawn.
- `app/controllers/investments/income_tax_reports_controller.rb` or the existing incomes controller, depending on the established route ownership after review.
- `app/views/investments/income_tax_reports/*` for year selection and the on-screen report.
- `app/views/investments/incomes/index.html.erb` for the report entry point.
- Request, service and PDF specs covering report behavior and access control.
- This governance plan and any focused code-map documentation required by the new report module.

## Risks

- Exposing another user's income through an insufficiently scoped report query.
- Divergence between the on-screen report and the generated PDF.
- Incorrect grouping or totals when records have missing optional reference dates.
- PDF layout problems for long reports, Portuguese characters, currency values, and page breaks.
- Adding a PDF dependency without preserving existing application startup and test behavior.

## Technical Strategy

1. Build the report from a policy-scoped income relation, filtered by the selected calendar year using `payment_date`.
2. Group records by asset, then by `income_type`; order records by `payment_date ASC`, with a stable `id ASC` tie-breaker.
3. Expose individual records with payment date, optional reference date, gross amount, tax amount, net amount and existing relevant fields.
4. Calculate subgroup totals from persisted records only, without inferring unavailable tax classifications or values.
5. Return one report data structure from the builder and reuse it in both the ERB view and the Prawn renderer.
6. Add an authenticated report route with a year parameter and a PDF response that uses the same report builder.
7. Handle empty years clearly in the view and PDF, and validate unsupported years without allowing unbounded or cross-user queries.
8. Add focused request, service and PDF specs before running the full suite.

## Architecture, Security and Performance Impact

- Architecture: keeps report aggregation independent from controllers, views and PDF formatting.
- Security: applies `policy_scope(Investments::Income)` before year filtering and does not accept arbitrary user or portfolio identifiers for report ownership.
- Performance: uses eager loading for assets and portfolios, performs year-scoped queries, and avoids per-record database queries while rendering.
- Compatibility: preserves existing income CRUD and overview behavior; the PDF dependency is isolated behind a report renderer.
- Frontend: adds a clear report action and a year selector while preserving the existing investment navigation and responsive layout.

## Database Impact

No migration or schema change is expected. Existing `payment_date`, `reference_date`, `gross_amount`, `tax_amount`, `net_amount`, asset and income type fields are sufficient.

## Checkpoints

1. Report data builder, year filtering, grouping, ordering, totals and service specs.
2. Authenticated on-screen report, entry point, route and request specs.
3. Prawn PDF renderer, download flow, PDF specs and full validation.
4. Final review, commit and pull request preparation.

Implementation will stop after each significant checkpoint for explicit review and approval. A stable commit will be created after each approved checkpoint.

## Required Tests

- Report builder specs for year filtering, asset/type grouping, ascending ordering, individual fields and subgroup totals.
- Empty year and incomplete optional data coverage.
- User isolation specs proving another user's incomes are excluded.
- Request specs for year selection, HTML report rendering and PDF download.
- PDF specs for grouping, ordering, totals, Portuguese text, currency formatting and multi-page output where practical.
- Existing income authorization and full RSpec suite.
- Route validation and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-10-15
