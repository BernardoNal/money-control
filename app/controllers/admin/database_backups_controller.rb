# frozen_string_literal: true

module Admin
  class DatabaseBackupsController < ApplicationController
    before_action :require_admin

    def show
    end

    def create
      backup = DatabaseBackup.call
      # send_data makes the download independent from the temporary file lifecycle.
      send_data File.binread(backup[:path]),
                filename: backup[:filename],
                type: "application/octet-stream",
                disposition: "attachment"
    rescue DatabaseBackup::Error => e
      redirect_to admin_database_backup_path, alert: e.message
    ensure
      # A database dump contains sensitive financial data and must not remain on disk
      # after the response has been prepared.
      File.delete(backup[:path]) if defined?(backup) && backup && File.exist?(backup[:path])
    end

    private

    def require_admin
      return if current_user&.admin?

      redirect_to root_path, alert: "Você não tem autorização para acessar essa página."
    end
  end
end
