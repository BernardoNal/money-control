// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Feature modules register their Turbo lifecycle handlers when imported.
import "components/modal"
import "components/searchable_select"
import "imports/import_review"
import "investments/asset_subcategory_filter"
import "investments/income_import_selection"
import "investments/portfolio_tabs"
import "navigation/mobile_navbar"
import "navigation/navbar_dropdowns"
import "privacy/privacy_mode"
import "transactions/transaction_form"
