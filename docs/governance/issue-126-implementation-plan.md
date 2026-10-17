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
4. Resolve categories through `Category.for_user(current_user.id)` during preview. Use global `Sem categoria (Entrada)` or `Sem categoria (Saída)` according to the normalized transaction direction when the user does not choose a more specific category; do not create user-specific categories automatically. The selected account is resolved once through `current_user.accounts` and stored on the draft.
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
4. Duplicate detection, pending-import recovery and cancellation.
5. Transaction usability improvements and account transaction overview.
6. Final review, full validation, commit and pull request preparation.

Implementation will stop after each significant checkpoint for explicit review and approval. A stable commit will be created only after a separate explicit authorization to commit; checkpoint approval alone does not authorize commit, push or pull request operations.

## Checkpoint 4 Addendum: Recovery and Duplicate Detection

### Objective

Allow users to recover pending imports from the account page, cancel abandoned drafts without losing audit history, and review possible duplicate transactions before confirmation.

### Affected Areas

- `app/models/transaction_import.rb` and `app/models/transaction.rb` for lifecycle and source metadata.
- A new incremental migration for `cancelled` import status, import origin and duplicate fingerprints.
- `app/services/transactions/imports/duplicate_detector.rb` and draft/confirmation services.
- `app/controllers/transactions/imports_controller.rb` and `accounts_controller.rb` for listing, resuming and cancelling drafts.
- Account and preview views for pending imports, duplicate warnings and per-row import selection.
- Request and service specs for ownership, lifecycle, duplicate matching and false-positive overrides.

### Technical Strategy

1. Add `cancelled` as a terminal import status. Cancellation updates the draft rather than deleting it, preserving filename, account, rows and timestamps.
2. List pending imports scoped through `current_user.accounts` on the account page, with actions to resume the preview or cancel the draft. Expired drafts remain non-confirmable and are shown with their status when relevant.
3. Persist source metadata on imported transactions: `transaction_import_id`, `source_document_number` and an account-scoped `import_fingerprint`. Existing manual transactions remain compatible through nullable fields.
4. Generate a deterministic fingerprint from the account, date, normalized amount, description, details, payment method and document number. Compare against existing transactions from the same account and against earlier rows in the current file.
5. Mark matches as `possible_duplicate` with a reason and default `selected: false`. Keep the user able to reselect a false positive during preview; confirmation imports only valid rows with `selected != false` and a category.
6. Treat duplicate detection as an advisory warning, not an automatic deletion or irreversible block. Never compare records across accounts or users.

### Data and Security Impact

- A new migration changes only the import/transaction source metadata and adds an account-scoped lookup index.
- Nullable source fields preserve existing transactions and manual entry behavior.
- Account ownership remains the authorization boundary for import listing, resuming, cancellation and duplicate matching.
- Fingerprints contain no secrets and are derived from already stored transaction fields.

### Risks and Mitigations

- False positives: show the matching reason and allow explicit re-selection.
- Duplicate rows inside one CSV: identify their source line and leave only the first occurrence selected by default.
- Large account histories: use the account/fingerprint index and bounded import rows.
- Abandoned drafts: cancellation is explicit and expiration remains a server-side confirmation guard.

### Required Tests

- Pending imports are listed only for the authenticated account owner.
- Resume and cancel preserve account isolation and terminal status behavior.
- Exact matches are warned and unselected by default.
- Different accounts with otherwise equal transactions do not match.
- False positives can be reselected and imported once.
- Duplicate detection does not affect manual transactions without source metadata.
- Full request/service suite and migration/schema validation.

## Checkpoint 5 Proposal: Transaction Usability

This checkpoint is a follow-up to the completed import workflow and should not change the import confirmation contract.

### Scope

- Define payment method options for transaction creation and editing, while preserving an `Outro` path for unsupported methods and existing values.
- Improve category selection in transaction create/edit by filtering categories according to entry/exit direction and making the field easier to scan and select.
- Improve the account show page with a scoped transaction section, including recent transactions, direction-aware amounts and useful empty/loading states.

### Technical Strategy

- Keep payment method normalization in the transaction boundary, with a controlled option list and backward-compatible storage in the existing field.
- Reuse the account ownership scope for transaction listing and avoid loading transactions from other accounts or users.
- Reuse the category direction rule already introduced by the import flow instead of duplicating incompatible filtering logic in the UI.
- Add focused request/model/view coverage for payment method persistence, category filtering, account transaction scope and empty accounts.

### Risks and Impact

- Existing free-text payment methods must continue rendering and editing correctly.
- Account pages must remain performant with bounded recent transaction queries.
- Category filtering must not prevent valid legacy records from being edited.
- No new persistence migration is expected unless the controlled payment method model requires one; the existing field remains the compatibility boundary.

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
