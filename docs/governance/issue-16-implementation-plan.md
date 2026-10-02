# Issue 16 Implementation Plan

## Objective

Add a search field to the investments assets index so users can filter the global asset catalog by name or ticker without changing the existing management flow.

## Affected Files

- `app/controllers/investments/assets_controller.rb`
- `app/components/search_field_component.rb`
- `app/components/search_field_component.html.erb`
- `app/views/investments/assets/index.html.erb`
- `spec/components/search_field_component_spec.rb`
- `spec/requests/investments/assets_spec.rb`
- `docs/governance/issue-16-implementation-plan.md`

## Risks

- Search filters could interfere with the existing category, subcategory, or offset pagination parameters.
- Unescaped user input in the SQL pattern could alter the intended search behavior.
- A broad contains search can become expensive as the global catalog grows.

## Technical Strategy

Keep the existing ordered relation and apply an optional case-insensitive `ILIKE` filter against `symbol` and `name`.

Escape wildcard characters with `sanitize_sql_like`, use a bound pattern, and retain all existing query parameters in pagination links.

Expose the current query in the index form through a reusable `SearchFieldComponent` and reuse the existing empty-state rendering for no matches.

## Database Impact

No migration or schema change. The current catalog size and existing symbol index are sufficient for this scoped search. A dedicated search index can be evaluated if catalog growth requires it.

## Required Tests

- request spec for matching by name
- request spec for matching by ticker, case-insensitively
- request spec for no matching results
- request spec confirming search works with existing filters and pagination links retain the query

## Approval

- status: approved
- approved by: user
- approval date: 2026-10-02
