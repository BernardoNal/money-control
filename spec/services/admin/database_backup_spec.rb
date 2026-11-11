require "rails_helper"
require "tmpdir"

RSpec.describe Admin::DatabaseBackup do
  let(:database_config) do
    {
      database: "money_control_test",
      host: "localhost",
      port: 5432,
      username: "postgres",
      password: "postgres"
    }
  end

  it "generates a timestamped custom-format backup without changing application data" do
    Dir.mktmpdir do |directory|
      status = double(success?: true)
      allow(Open3).to receive(:capture3) do |_environment, *command|
        backup_path = command[command.index("--file") + 1]
        File.write(backup_path, "backup content")
        ["", "", status]
      end

      result = described_class.call(
        output_directory: directory,
        now: Time.zone.parse("2026-11-11 14:30:45"),
        database_config: database_config
      )

      expect(result[:filename]).to eq("money_control_backup_2026-11-11_14-30-45.dump")
      expect(File.binread(result[:path])).to eq("backup content")
      expect(Open3).to have_received(:capture3).with(
        {
          "PGHOST" => "localhost",
          "PGPORT" => "5432",
          "PGUSER" => "postgres",
          "PGPASSWORD" => "postgres"
        },
        "pg_dump",
        "--format=custom",
        "--no-owner",
        "--no-privileges",
        "--file",
        result[:path],
        "money_control_test"
      )
    end
  end

  it "removes a failed output and reports the pg_dump error" do
    Dir.mktmpdir do |directory|
      status = double(success?: false, exitstatus: 1)
      allow(Open3).to receive(:capture3) do |_environment, *command|
        backup_path = command[command.index("--file") + 1]
        File.write(backup_path, "partial backup")
        ["", "permission denied", status]
      end

      expect do
        described_class.call(
          output_directory: directory,
          now: Time.zone.parse("2026-11-11 14:30:45"),
          database_config: database_config
        )
      end.to raise_error(Admin::DatabaseBackup::Error, "Database backup failed: permission denied")

      expect(Dir.children(directory)).to be_empty
    end
  end
end
