# Development Workflow

This workflow is mandatory for every project change.

## 1. Branch

Never work directly on `main`, `master`, or `production`.

Create a dedicated branch first:

- `feature/name`
- `fix/name`
- `refactor/name`
- `hotfix/name`

Examples:

- `feature/investments-module`
- `fix/account-update-bug`
- `refactor/transactions-domain`

## 2. Analysis

Before implementation, review the impact on:

- architecture
- database
- security
- performance
- tests
- compatibility

## 3. Implementation Plan

The plan must contain:

- objective
- affected files
- risks
- technical strategy
- database impact
- required tests

## 4. Approval

Implementation only starts after explicit approval.

Flow:

1. Analysis
2. Plan
3. Approval
4. Implementation

## 5. Execution Follow-Up

For longer changes, keep progress visible:

- what is done
- what is in progress
- what is left
- blockers or risks
- strategy changes

## 6. Mandatory Review

After implementation, review:

### Architecture

- organization
- coupling
- class responsibilities

### Security

- user scoping
- authorization
- data leaks
- mass assignment

### Performance

- queries
- N+1
- eager loading
- unnecessary queries

### Database

- indexes
- foreign keys
- constraints
- nullable mistakes

### Rails Quality

- Rails conventions
- method names
- cohesion
- single responsibility

### Frontend

- responsiveness
- visual consistency
- Turbo and Hotwire behavior
- accessibility

### Tests

- broken specs
- coverage
- regressions
- factories or fixtures
- Devise authentication

## 7. Final Checklist

Every delivery must validate:

- [ ] All tests passed
- [ ] No broken routes
- [ ] No invalid references
- [ ] No unsafe queries
- [ ] No unscoped `Model.all`
- [ ] No unauthorized `find`
- [ ] No old migration changed
- [ ] No secret exposed
- [ ] No critical warning left
- [ ] Code follows the project standard

## 8. Pull Request

Every delivery must include:

- summary
- motivation
- main changes
- impacts
- evidence

Evidence may include:

- screenshots
- logs
- test results

## 9. Continuous Refactoring

When touching a module:

- fix nearby inconsistencies
- remove dead code
- improve poor names
- improve local organization
- reduce small technical debt

Do not expand into large unrelated refactors.

## 10. Operating Principles

Prioritize:

- predictability
- traceability
- security
- future maintenance
- scalability
- clarity
- simplicity

Speed must never compromise architecture.

## 11. Completion Rule

No change is complete without:

- final review
- tests
- architectural validation
- security validation
- complete functional confirmation
