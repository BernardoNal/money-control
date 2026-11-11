# frozen_string_literal: true

require "fileutils"
require "open3"

module Admin
  class DatabaseBackup
    class Error < StandardError; end

    def self.call(output_directory: Dir.tmpdir, now: Time.current, database_config: nil)
      new(
        output_directory: output_directory,
        now: now,
        database_config: database_config
      ).call
    end

    def initialize(output_directory:, now:, database_config:)
      @output_directory = output_directory
      @now = now
      @database_config = database_config || ActiveRecord::Base.connection_db_config.configuration_hash
    end

    def call
      FileUtils.mkdir_p(@output_directory)

      path = File.join(@output_directory, filename)
      _stdout, stderr, status = Open3.capture3(command_environment, *command(path))

      unless status.success?
        File.delete(path) if File.exist?(path)
        raise Error, "Database backup failed: #{stderr.strip.presence || "pg_dump exited with status #{status.exitstatus}"}"
      end

      { path: path, filename: filename }
    rescue Errno::ENOENT => e
      raise Error, "Unable to create database backup: #{e.message}"
    end

    private

    def filename
      "money_control_backup_#{@now.strftime("%Y-%m-%d_%H-%M-%S")}.dump"
    end

    def command(path)
      [
        "pg_dump",
        "--format=custom",
        "--no-owner",
        "--no-privileges",
        "--file", path,
        @database_config.fetch(:database)
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
