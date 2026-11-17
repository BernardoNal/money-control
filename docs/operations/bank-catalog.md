# Brazilian bank catalog

The application maintains a local catalog of Brazilian institutions using the Banco Central do Brasil list of STR participants.

## Source

The source is the official [Participantes do STR CSV](https://www.bcb.gov.br/content/estabilidadefinanceira/str1/ParticipantesSTR.csv), published by the Banco Central. It provides the ISPB, reduced name, number-code, full name, and operation start date.

The catalog is synchronized explicitly and is not requested during normal account form usage. This keeps the application usable when the external source is unavailable.

## Synchronize

Run the task in the environment whose local catalog should be updated:

```bash
bin/rails bank_catalog:sync
```

The task upserts records using the source and external bank code as the identity. Repeated source rows are deduplicated, and rows without a usable bank code, such as `n/a`, are reported as invalid and ignored.

The task does not change the existing `accounts.bank` field or rewrite existing accounts. The local catalog is currently an independent foundation for future account-form and import integrations.

## Stored data

- `bank_code`: Banco Central external number-code.
- `ispb`: Banco Central payment-system identifier.
- `name`: full institution name.
- `short_name`: reduced institution name.
- `source`: source identifier, currently `bcb_str` for synchronized records.
- `active`: whether the record is currently represented by the source.

The source is public, but catalog refreshes should still be reviewed because institutions and classifications can change over time.
