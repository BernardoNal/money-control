# Database backup and restore

The application supports administrator-generated PostgreSQL backups in custom dump format.

## Generate a backup

An administrator can open **Backup do banco** from the account menu and download a `.dump` file. The file contains application structure and data, including sensitive financial records. Store it outside the application in a protected location.

Backup generation uses `pg_dump` and does not change the current database.

## Restore a backup

Restore is intentionally available only as a deployment or maintenance command. It is destructive because existing objects in the target database may be replaced.

```bash
bin/rails db:restore BACKUP=/path/to/money_control_backup_YYYY-MM-DD_HH-MM-SS.dump CONFIRM_RESTORE=YES
```

The command requires all of the following:

- `BACKUP` must point to an existing readable PostgreSQL custom-format dump.
- `CONFIRM_RESTORE=YES` must be provided explicitly.
- The Rails environment must be configured for the target database.

The original backup file is never deleted or modified. Take an additional backup of the target database before restoring, and ensure the application is stopped or placed in maintenance mode so requests do not run during the operation.
