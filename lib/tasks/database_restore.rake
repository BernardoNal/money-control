namespace :db do
  desc "Restore a PostgreSQL custom-format backup after explicit confirmation"
  task restore: :environment do
    backup_path = ENV["BACKUP"]

    if backup_path.blank?
      abort "BACKUP is required. Example: bin/rails db:restore BACKUP=/path/to/backup.dump CONFIRM_RESTORE=YES"
    end

    database_config = ActiveRecord::Base.connection_db_config.configuration_hash
    # Release Rails' active database session before pg_restore drops or recreates
    # objects in the same database.
    ActiveRecord::Base.connection_pool.disconnect!

    Admin::DatabaseRestore.call(
      backup_path: backup_path,
      confirmation: ENV["CONFIRM_RESTORE"],
      database_config: database_config
    )

    puts "Database restored from #{File.expand_path(backup_path)}"
  rescue Admin::DatabaseRestore::Error => e
    abort e.message
  end
end
