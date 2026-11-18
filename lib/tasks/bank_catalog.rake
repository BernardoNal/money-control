namespace :bank_catalog do
  desc "Synchronize the local bank catalog with Banco Central STR data"
  task sync: :environment do
    # This is an explicit maintenance task, not a runtime dependency of account forms.
    records = BankCatalog::BcbClient.call
    result = BankCatalog::Synchronizer.call(records: records, source: "bcb_str")

    puts "Bank catalog synchronized: #{result.upserted_count} records upserted, #{result.invalid_count} invalid records ignored."
  rescue BankCatalog::BcbClient::Error => e
    abort e.message
  end
end
