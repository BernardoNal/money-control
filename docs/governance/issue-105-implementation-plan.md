# Issue 105 Implementation Plan

## Objective

Remove the ambiguous `stringio` gem specification warning while preserving the dependency version resolved by the project.

## Affected Files

- `Gemfile`
- `Gemfile.lock`
- `bin/dev`
- `docs/governance/issue-105-implementation-plan.md`

## Risks

- Pinning an incompatible version for the project's Ruby version
- Changing unrelated transitive dependencies while refreshing the lockfile
- Treating a local gem installation problem as a repository dependency problem

## Technical Strategy

Declare `stringio` explicitly in the `Gemfile` using the already resolved 3.1 series.

Refresh only the relevant lockfile entries and verify that Bundler continues to resolve `stringio` to the expected version.

The diagnostic warning from direct `gem` queries may remain because Ruby 3.2 includes `stringio 3.0.4` as a default gem alongside the installed `3.1` series. Avoid those queries in project scripts; do not remove the default gem as part of this repository change.

## Database Impact

None.

## Required Tests

- `bundle check`
- normal Rails command without an ambiguous stringio warning
- `bin/dev` startup check without an ambiguous stringio warning
- relevant RSpec suite

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-23
