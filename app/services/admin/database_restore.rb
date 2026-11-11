# frozen_string_literal: true

require "open3"

module Admin
  class DatabaseRestore
    class Error < StandardError; end

    def self.call(backup_path:, confirmation:, database_config: nil)
      new(
        backup_path: backup_path,
        confirmation: confirmation,
        database_config: database_config
      ).call
    end

    def initialize(backup_path:, confirmation:, database_config:)
      @backup_path = File.expand_path(backup_path.to_s)
      @confirmation = confirmation
      @database_config = database_config || ActiveRecord::Base.connection_db_config.configuration_hash
    end

    def call
      # Restoring can replace existing database objects, so validation must happen
      # before pg_restore is started and before any database connection is changed.
      validate_request!

      _stdout, stderr, status = Open3.capture3(command_environment, *command)
      return true if status.success?

      raise Error, "Database restore failed: #{stderr.strip.presence || "pg_restore exited with status #{status.exitstatus}"}"
    rescue Errno::ENOENT => e
      raise Error, "Unable to restore database: #{e.message}"
    end

    private

    def validate_request!
      # The explicit environment flag prevents an accidental restore from a copied
      # command, an incomplete deployment configuration, or a missing file path.
      raise Error, "Set CONFIRM_RESTORE=YES to confirm the database restore." unless @confirmation == "YES"
      raise Error, "Backup file does not exist or is not readable: #{@backup_path}" unless File.file?(@backup_path) && File.readable?(@backup_path)
    end

    def command
      # pg_restore receives an argument array, never a shell string. The original
      # dump remains untouched; only the target database is modified by this command.
      [
        "pg_restore",
        "--clean",
        "--if-exists",
        "--exit-on-error",
        "--no-owner",
        "--no-privileges",
        "--dbname", @database_config.fetch(:database),
        @backup_path
      ]
    end

    def command_environment
      {
        "PGHOST" => @database_config[:host].presence,
        "PGPORT" => @database_config[:port].presence&.to_s,
        "PGUSER" => @database_config[:username].presence,
        "PGPASSWORD" => @database_config[:password].presence
      }.compact
    end
  end
end
