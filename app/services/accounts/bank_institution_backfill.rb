# frozen_string_literal: true

module Accounts
  class BankInstitutionBackfill
    Result = Struct.new(:matched, :ambiguous, :unmatched, keyword_init: true)

    def self.call(apply: false, accounts: nil)
      new(apply: apply, accounts: accounts).call
    end

    def initialize(apply:, accounts:)
      @apply = apply
      @accounts = accounts || Account.where(bank_institution_id: nil).where.not(bank: [nil, ""])
    end

    def call
      catalog = BankInstitution.all.to_a
      matched = []
      ambiguous = []
      unmatched = []

      @accounts.find_each do |account|
        candidates = matching_institutions(account.bank, catalog)

        case candidates.length
        when 1
          institution = candidates.first
          account.update!(bank_institution: institution) if @apply
          matched << { account: account, bank_institution: institution }
        when 0
          unmatched << { account: account, bank_name: account.bank }
        else
          ambiguous << { account: account, bank_name: account.bank, candidates: candidates }
        end
      end

      Result.new(matched: matched, ambiguous: ambiguous, unmatched: unmatched)
    end

    private

    def matching_institutions(bank_name, catalog)
      normalized_bank_name = normalize(bank_name)

      catalog.select do |institution|
        [institution.name, institution.short_name].compact.any? do |candidate_name|
          normalize(candidate_name) == normalized_bank_name
        end
      end
    end

    # Exact normalized matches are intentional: fuzzy matching could link an
    # account to the wrong institution when names share a brand or prefix.
    def normalize(value)
      I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, " ").squeeze(" ").strip
    end
  end
end
