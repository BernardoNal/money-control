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

  desc "Preview or apply safe account bank institution associations"
  task backfill_accounts: :environment do
    apply = ENV["APPLY"] == "true"
    result = Accounts::BankInstitutionBackfill.call(apply: apply)

    puts "Account bank backfill #{apply ? "applied" : "preview"}:"
    puts "  Matched: #{result.matched.length}"
    puts "  Ambiguous: #{result.ambiguous.length}"
    puts "  Unmatched: #{result.unmatched.length}"

    result.ambiguous.each do |entry|
      candidates = entry[:candidates].map { |institution| "#{institution.bank_code} - #{institution.short_name || institution.name}" }.join(", ")
      puts "  Ambiguous account #{entry[:account].id} (#{entry[:bank_name]}): #{candidates}"
    end

    result.unmatched.each do |entry|
      puts "  Unmatched account #{entry[:account].id}: #{entry[:bank_name]}"
    end
  end
end
