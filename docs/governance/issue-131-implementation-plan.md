# Issue 131 Implementation Plan

## Objective

Import investment income from brokerage XLSX statements while preserving user review for ambiguous rows.

## Domain Decisions

- `DIVIDENDOS DE CLIENTES` maps to dividends.
- `JUROS S/ CAPITAL DE CLIENTES` maps to interest on equity (JCP).
- `RENDIMENTOS DE CLIENTES` maps to FII income for the initial format.
- `Crédito Ref. Taxa de Remuneração BTC` maps to securities lending income.
- `AMORTIZAÇÃO` maps to amortization.
- IRRF and brokerage fees remain separate financial adjustments.
- `CREDITO DE REEMBOLSO DE EVENTO` is ambiguous and requires manual confirmation before persistence.

## Checkpoint 1: XLSX Parser

Completed the parser boundary for the observed brokerage statement:

- reads the first worksheet from an XLSX package;
- recognizes movement, settlement, description, amount and balance columns;
- converts Excel serial dates and Brazilian amounts;
- extracts common tickers from descriptions;
- classifies known movement descriptions;
- preserves ambiguous classifications for later review;
- stops at the broker's no-movements marker;
- reports invalid headers and malformed workbooks.

## Affected Areas

- `app/services/investments/income_imports/xlsx_parser.rb`
- `spec/services/investments/income_imports/xlsx_parser_spec.rb`
- `Gemfile` and `Gemfile.lock` for the direct XLSX archive dependency.

## Next Checkpoints

1. Add portfolio-scoped upload and persisted preview.
2. Add manual classification and asset review.
3. Validate taxes, fees, assets and duplicate candidates.
4. Confirm income atomically and integrate existing reports.

## Validation

- XLSX parser specs: 3 examples, 0 failures.
- `bundle check` passed.
- `git diff --check` passed.

## Approval

- status: checkpoint 1 implemented
- approval required before continuing to checkpoint 2
