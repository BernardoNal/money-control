# Issue 114 Implementation Plan

## Objective

Protect the global investment asset catalog by allowing authenticated users to read it while restricting catalog mutations to administrators.

## Affected Files

- `app/policies/investments/asset_policy.rb`
- `app/controllers/investments/assets_controller.rb`
- `spec/policies/investments/asset_policy_spec.rb`
- `spec/requests/investments/assets_spec.rb`
- `docs/governance/issue-114-implementation-plan.md`

## Risks

- Blocking existing asset creation and update flows for non-admin users without clear authorization feedback
- Forgetting to authorize one mutation entrypoint such as new, create, edit or update
- Accidentally restricting read-only listing and search flows
- Relying on a mutable request parameter instead of the persisted admin flag

## Technical Strategy

1. Add an `Investments::AssetPolicy` for the global catalog.
2. Keep index and search available to authenticated users.
3. Require `user.admin?` for new, create, edit and update actions.
4. Authorize asset instances at every mutation entrypoint, including new and create.
5. Preserve the global asset model and existing market lookup behavior.
6. Add policy and request specs for regular users, administrators, listing, search, create and update.

## Checkpoints

1. Policy and controller authorization for asset mutation entrypoints, with policy specs.
2. Request regression coverage for admin and regular-user asset flows.
3. Full validation, security review and delivery preparation.

## Architecture, Security and Performance Impact

- Architecture: keeps authorization in Pundit and the controller boundary without changing the global catalog model.
- Security: prevents regular users from creating or modifying shared market assets.
- Performance: no new unbounded query is introduced; authorization uses the persisted user admin flag.
- Compatibility: authenticated read-only listing and search remain available.

## Database Impact

No migration or schema change is expected. The existing users.admin flag is reused.

## Required Tests

- Policy specs for regular users and administrators.
- Request specs for authorized and unauthorized create/update flows.
- Regression specs confirming listing and search remain available to regular users.
- `bundle exec rspec`, route validation and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-09-27
