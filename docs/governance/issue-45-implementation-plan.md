# Issue 45 Implementation Plan

## Objective

Complete asset category support by exposing the existing asset category enum through forms and category-based filters.

## Affected Files

- `app/controllers/investments/assets_controller.rb`
- `app/views/investments/assets/index.html.erb`
- `app/views/investments/assets/form.html.erb`
- `app/views/investments/assets/show.html.erb`
- `config/routes.rb`
- `app/views/shared/_navbar.html.erb`
- `spec/requests/investments/assets_spec.rb`

## Risks

- Treating a partially completed model issue as finished without exposing the enum in UI
- Creating filters that do not preserve only valid category values
- Introducing an asset CRUD flow without keeping it consistent with the investments namespace

## Technical Strategy

Build a basic CRUD flow for `Investments::Asset` and reuse the existing category enum already implemented in the model.

Expose category through:

- asset creation form
- asset editing form
- asset list filter

Use the category enum keys to populate both the form select and the filter select.

## Database Impact

No database changes are required for this issue.

The asset category enum and data structure already exist.

## Required Tests

- request specs for listing assets
- request specs for filtering by category
- request specs for create and update with category
- request specs for show rendering

## Approval

- status: approved
- approved by: user
- approval date: 2026-06-02
