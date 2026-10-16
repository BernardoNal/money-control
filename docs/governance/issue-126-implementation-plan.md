# Issue 126 Implementation Plan

## Objective

Add a reusable CSV import workflow for financial transactions. Users should upload a CSV, review normalized and validated rows, understand invalid or ignored rows, and explicitly confirm a transactionally safe import.

## Affected Areas

- `db/migrate/*` and `db/schema.rb` for a user-scoped import draft persistence layer.
- `app/models/transaction_import.rb` and related validation/status code.
- `app/services/transactions/imports/*` for parser, normalization, validation and persistence responsibilities.
- `app/controllers/transactions/imports_controller.rb` for upload, preview and confirmation endpoints.
- `config/routes.rb` for the import workflow routes.
- `app/views/transactions/imports/*` and `app/views/transactions/index.html.erb` for upload, preview, result and entry-point UI.
- Request, model and service specs for parsing, validation, authorization, preview and atomic confirmation.
- This governance plan and code-map documentation if the new import boundary becomes a permanent domain area.

## Risks

- Importing transactions into another user's account or category.
- Persisting a partial import after a failed confirmation.
- Treating malformed dates, localized amounts or unsupported headers as valid.
- Storing untrusted CSV content without size, encoding or row-count limits.
- Replaying a confirmation and creating duplicate transactions.
- Making the shared workflow depend on one institution's column names.

## Technical Strategy

1. Make the workflow account-scoped: the user selects an account before uploading, and every imported transaction is assigned to that fixed account. The CSV does not need an account column.
2. Define a normalized row contract with required `date`, `amount` and `description` fields, plus optional `category_name`, `to_whom`, `document_number`, `transaction_type` and `payment_method` fields.
3. Add a parser boundary with an institution-independent CSV parser first, plus a Banco do Brasil-compatible header profile for the supplied statement format. Support explicit Portuguese and English header aliases, UTF-8/BOM input, Brazilian monetary formats, and clear unsupported-header errors. Keep future institution-specific parsers behind the same interface.
4. Resolve categories through `Category.for_user(current_user.id)` during preview. Do not create categories automatically; the user assigns a category per row, and rows without a category remain pending validation. The selected account is resolved once through `current_user.accounts` and stored on the draft.
5. Validate every normalized row before persistence, including required fields, date, amount and row-level format errors. Keep valid, invalid and intentionally ignored rows visible in the preview.
6. Persist the preview as an account-scoped `TransactionImport` draft with normalized row data, per-row category selections and validation status in JSONB, plus original filename and summary metadata. Apply upload size and row-count limits before persistence.
7. Confirm only valid rows inside one `ActiveRecord::Base.transaction`, re-checking the selected account, category ownership and draft status. Mark the draft completed only after all transactions save; any failure rolls back every transaction.
8. Make confirmation idempotent by rejecting completed or expired drafts and never accepting a client-provided account ownership boundary.
9. Reuse existing transaction fields and Brazilian formatting conventions in the preview and result screens.

## Architecture, Security and Performance Impact

- Architecture: separates CSV parsing, normalized validation, draft persistence, controller orchestration and transaction creation.
- Security: every draft and account lookup is scoped through `current_user.accounts`; category lookup uses `Category.for_user(current_user.id)`. Uploaded filenames and CSV values are treated as untrusted input.
- Performance: parses bounded input, eager-loads or preloads account/category lookup maps, and performs confirmation in one transaction with bounded row counts.
- Compatibility: existing manual transaction creation and listing remain unchanged; institution-specific parsers can be added without replacing the workflow.
- Frontend: adds an explicit upload, preview and confirmation flow with clear invalid/ignored row reasons and no automatic persistence on upload.

## Database Impact

Add a new account-owned import draft table, expected to include:

- `account_id` foreign key and index. The account is the ownership boundary and connects the import to the authenticated user through `accounts.user_id`.
- original filename, status and timestamps.
- normalized rows and validation summary in JSONB.
- optional expiration/completion metadata if required by the confirmation flow.

The expected table shape is:

```ruby
create_table :transaction_imports do |t|
  t.references :account, null: false, foreign_key: true, index: true
  t.string :original_filename, null: false
  t.string :status, null: false, default: "pending"
  t.jsonb :rows, null: false, default: []
  t.jsonb :summary, null: false, default: {}
  t.datetime :expires_at
  t.datetime :completed_at
  t.timestamps
end
```

No columns will be added or changed in the existing `transactions`, `accounts` or `categories` tables. Confirmed rows will reuse the existing `transactions.account_id` foreign key.

## Checkpoints

1. Parser boundary, normalized row contract, format validation and parser/service specs.
2. User-scoped import draft persistence, upload/preview routes and preview UI.
3. Atomic confirmation, result handling, user-isolation and workflow request specs.
4. Final review, full validation, commit and pull request preparation.

Implementation will stop after each significant checkpoint for explicit review and approval. A stable commit will be created after each approved checkpoint.

## Required Tests

- CSV parsing with Portuguese/English aliases, BOM, Brazilian amounts, dates and unsupported headers.
- Invalid, unsupported and intentionally ignored row reasons.
- File size, row count, missing file and malformed encoding handling.
- Draft ownership and account/category isolation.
- Preview does not persist transactions.
- Confirmation persists only valid rows atomically.
- Confirmation failure rolls back all rows and completed drafts cannot be replayed.
- Existing transaction request/policy specs and full RSpec suite.
- Route validation, dependency checks and `git diff --check`.

## Approval

- status: approved
- approved by: user
- approval date: 2026-10-16
