# Issue 38 Implementation Plan

## Objective

Implement a service object to calculate average price for one asset inside one investment portfolio, based on transaction history.

## Affected Files

- `app/services/investments/average_price_calculator.rb`
- `spec/services/investments/average_price_calculator_spec.rb`

## Risks

- Misinterpreting how sell operations should affect average price
- Mixing transactions from other portfolios or assets in the calculation
- Failing to handle invalid historical data, such as selling more than the current position

## Technical Strategy

Implement `Investments::AveragePriceCalculator` as a service object that receives:

- `portfolio`
- `asset`

The service should:

- consider only buy and sell transactions
- process transactions in chronological order
- calculate weighted average price for buys, including fees
- reduce quantity and total cost proportionally on sells
- reset average price when the position becomes zero
- raise an error if a sell exceeds the current position

The service should return a result object with:

- `quantity`
- `total_cost`
- `average_price`

## Database Impact

No database changes are required for this issue.

The calculation is derived from existing `investments_transactions` data.

## Required Tests

- empty history returns zero values
- class-level call interface works
- weighted average calculation for buys
- partial sell keeps average price and reduces cost proportionally
- full sell resets position and average price
- transactions from other portfolios or assets are ignored
- invalid sell history raises an error

## Approval

- status: approved
- approved by: user
- approval date: 2026-05-26
