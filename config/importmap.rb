# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.16
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.13
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.0.200

pin_all_from "app/javascript/components", under: "components"
pin_all_from "app/javascript/imports", under: "imports"
pin_all_from "app/javascript/investments", under: "investments"
pin_all_from "app/javascript/navigation", under: "navigation"
pin_all_from "app/javascript/privacy", under: "privacy"
pin_all_from "app/javascript/transactions", under: "transactions"
