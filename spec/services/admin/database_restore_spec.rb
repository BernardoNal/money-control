require "rails_helper"
require "tempfile"

RSpec.describe Admin::DatabaseRestore do
  let(:database_config) do
    {
      database: "money_control_test",
      host: "localhost",
      port: 5432,
      username: "postgres",
      password: "postgres"
    }
  end

  it "requires explicit confirmation before running pg_restore" do
    expect do
      described_class.call(
        backup_path: "/tmp/backup.dump",
        confirmation: "NO",
        database_config: database_config
      )
    end.to raise_error(Admin::DatabaseRestore::Error, /CONFIRM_RESTORE=YES/)

    expect(Open3).not_to receive(:capture3)
  end

  it "rejects a missing backup file" do
    expect do
      described_class.call(
        backup_path: "/tmp/missing-money-control-backup.dump",
        confirmation: "YES",
        database_config: database_config
      )
    end.to raise_error(Admin::DatabaseRestore::Error, /does not exist or is not readable/)
  end

  it "restores a readable backup without modifying the original file" do
    Tempfile.create(["money_control_backup", ".dump"]) do |file|
      file.write("backup content")
      file.flush
      status = double(success?: true)
      allow(Open3).to receive(:capture3).and_return(["", "", status])

      result = described_class.call(
        backup_path: file.path,
        confirmation: "YES",
        database_config: database_config
      )

      expect(result).to be(true)
      expect(File.binread(file.path)).to eq("backup content")
      expect(Open3).to have_received(:capture3).with(
        {
          "PGHOST" => "localhost",
          "PGPORT" => "5432",
          "PGUSER" => "postgres",
          "PGPASSWORD" => "postgres"
        },
        "pg_restore",
        "--clean",
        "--if-exists",
        "--exit-on-error",
        "--no-owner",
        "--no-privileges",
        "--dbname",
        "money_control_test",
        file.path
      )
    end
  end
end
