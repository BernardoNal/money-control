# Issue 83 Implementation Plan

## Objective

Modernize the application's global UX/UI by redesigning the authentication experience and the shared application shell so they become visually consistent with the Investments module, without changing business rules.

## Affected Files

- `app/views/layouts/application.html.erb`
- `app/views/shared/_navbar.html.erb`
- `app/assets/tailwind/application.css`
- `app/helpers/application_helper.rb`
- `app/views/devise/sessions/new.html.erb`
- `app/views/devise/registrations/new.html.erb`
- `app/views/devise/registrations/edit.html.erb`
- `app/views/devise/passwords/new.html.erb`
- `app/views/devise/passwords/edit.html.erb`
- `app/views/devise/confirmations/new.html.erb`
- `app/views/devise/unlocks/new.html.erb`
- `app/views/devise/shared/_links.html.erb`
- `app/views/devise/shared/_error_messages.html.erb`
- `spec/requests/investments/portfolios_spec.rb`
- `spec/requests/investments/transactions_spec.rb`
- `spec/requests/accounts_spec.rb`
- `spec/requests/transactions_spec.rb`
- `spec/requests/categories_spec.rb`

## Risks

- Introducing visual changes in the global layout that unintentionally break spacing or responsiveness in existing authenticated pages
- Reworking shared navigation in a way that hurts usability on smaller screens or removes important access points
- Changing Devise views without preserving all authentication links, error feedback, or accessibility expectations
- Letting global Tailwind base styles become too aggressive and alter unrelated screens unexpectedly

## Technical Strategy

Refresh the application shell first, then adapt authentication screens to reuse the same visual language.

Application shell:

- redesign `application.html.erb` so authenticated and unauthenticated experiences can have different wrappers while still sharing the same layout entry point
- refactor `shared/_navbar.html.erb` into a more polished navigation shell with clearer hierarchy, active states, and a stronger user profile area
- centralize small helper methods in `ApplicationHelper` only when needed for navigation state or reusable UI behavior
- tune `app/assets/tailwind/application.css` carefully so base tokens such as page background, typography, inputs, and focus states align better with the Investments module without causing broad regressions

Authentication:

- redesign the Devise pages with a consistent card/layout structure, improved hierarchy, and responsive behavior
- keep all existing authentication flows intact, including sign in, registration, password recovery, confirmation, unlock, and account editing
- preserve Devise error rendering and shared links while modernizing presentation and accessibility
- adopt `#000080` as the preferred primary button color for the refreshed authentication experience, keeping semantic exceptions such as destructive actions in red

Implementation approach:

- keep the work strictly in views/helpers/styles
- avoid controller or domain behavior changes
- validate affected screens manually after each group of changes
- review neighboring authenticated pages, especially investments dashboards and CRUD pages, to confirm the new shell still fits existing content

## Database Impact

No database changes are required for this issue.

The work is limited to UX/UI updates in shared layout, styles, helpers, and Devise views.

## Required Tests

- request specs covering authenticated pages should continue to pass to ensure the shared shell does not break rendered flows
- request specs for Devise-adjacent authenticated pages should be re-run as regression coverage
- manual UI validation for:
  - login page
  - registration page
  - password recovery and reset pages
  - account edit page
  - main authenticated navigation on desktop
  - main authenticated navigation on mobile width
  - at least one Investments screen, one Accounts screen, and one Transactions screen

## Approval

- status: approved
- approved by: user
- approval date: 2026-07-17
