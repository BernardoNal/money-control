# frozen_string_literal: true

module BankCatalog
  class Synchronizer
    Result = Struct.new(:upserted_count, :invalid_count, keyword_init: true)

    def self.call(records:, source: "bcb", synced_at: Time.current)
      new(records: records, source: source, synced_at: synced_at).call
    end

    def initialize(records:, source:, synced_at:)
      @records = records
      @source = source
      @synced_at = synced_at
    end

    def call
      # The synchronizer accepts normalized records from any source adapter.
      # Keeping persistence here prevents external API details from reaching the model.
      normalized_records, invalid_count = normalize_records

      BankInstitution.upsert_all(
        normalized_records,
        unique_by: :index_bank_institutions_on_source_and_bank_code
      ) if normalized_records.any?

      Result.new(
        upserted_count: normalized_records.length,
        invalid_count: invalid_count
      )
    end

    private

    def normalize_records
      deduplicated = {}
      invalid_count = 0

      @records.each do |record|
        normalized = normalize_record(record)
        if normalized
          # The last occurrence wins so a repeated source row does not violate
          # the unique source/code constraint during the same synchronization.
          deduplicated[normalized[:bank_code]] = normalized
        else
          # Invalid source rows are reported to the caller instead of aborting
          # all valid institutions from the same payload.
          invalid_count += 1
        end
      end

      [deduplicated.values, invalid_count]
    end

    def normalize_record(record)
      bank_code = record[:bank_code].presence || record["bank_code"].presence
      name = record[:name].presence || record["name"].presence
      return if bank_code.blank? || name.blank?

      {
        bank_code: bank_code.to_s.strip,
        ispb: value(record, :ispb),
        name: name.to_s.strip,
        short_name: value(record, :short_name),
        institution_type: value(record, :institution_type),
        source: @source,
        active: record[:active].nil? ? record["active"].nil? ? true : record["active"] : record[:active],
        source_updated_at: value(record, :source_updated_at),
        created_at: @synced_at,
        updated_at: @synced_at
      }
    end

    def value(record, key)
      record[key].presence || record[key.to_s].presence
    end
  end
end
