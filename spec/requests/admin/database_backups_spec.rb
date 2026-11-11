require "rails_helper"
require "tempfile"

RSpec.describe "Admin::DatabaseBackups", type: :request do
  let(:user) do
    User.create!(
      name: "Backup User",
      email: "backup-user@example.com",
      password: "password123",
      admin: false
    )
  end

  let(:admin) do
    User.create!(
      name: "Backup Admin",
      email: "backup-admin@example.com",
      password: "password123",
      admin: true
    )
  end

  it "denies the backup page to regular users" do
    sign_in user

    get admin_database_backup_path

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("Você não tem autorização para acessar essa página.")
  end

  it "allows administrators to open the backup page" do
    sign_in admin

    get admin_database_backup_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Backup do banco de dados", "Gerar e baixar backup", "Backup do banco")
    expect(response.body).to include('<button type="submit"')
    expect(response.body).to include('data-turbo="false"')
  end

  it "downloads and removes the temporary backup file for administrators" do
    sign_in admin

    Tempfile.create(["money_control_backup", ".dump"]) do |file|
      file.write("backup content")
      file.flush
      allow(Admin::DatabaseBackup).to receive(:call).and_return(
        path: file.path,
        filename: "money_control_backup_2026-11-11_14-30-45.dump"
      )

      post admin_database_backup_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("money_control_backup_2026-11-11_14-30-45.dump")
      expect(response.body).to eq("backup content")
      expect(File).not_to exist(file.path)
    end
  end
end
