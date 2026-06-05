# Issue 39 Implementation Plan

## Objective

Implement a service object to calculate the current quantity held for one asset inside one investment portfolio from transaction history.

## Affected Files

- `app/services/investments/current_position_calculator.rb`
- `spec/services/investments/current_position_calculator_spec.rb`

## Risks

- Misinterpreting how sell operations should reduce the current position
- Mixing transactions from other portfolios or assets in the calculation
- Failing to detect invalid history where sell quantity exceeds the current position

## Technical Strategy

Implement `Investments::CurrentPositionCalculator` as a service object that receives:

- `portfolio`
- `asset`

The service should:

- consider buy and sell transactions
- process transactions in chronological order
- increase quantity on buys
- reduce quantity on sells
- raise an error if a sell exceeds the current position
- ignore transactions from other portfolios or assets
- ignore other transaction types for now

The service should return a small result object with:

- `quantity`

## Database Impact

No database changes are required for this issue.

The calculation is derived from existing `investments_transactions` data.

## Required Tests

- empty history returns zero quantity
- class-level call interface works
- multiple buys accumulate quantity
- partial sell reduces quantity
- full sell resets quantity to zero
- transactions from other portfolios or assets are ignored
- invalid sell history raises an error

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-26
