defmodule HomeWare.Repo.Migrations.CreateMailMessages do
  use Ecto.Migration

  def change do
    create table(:mail_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :subject, :string, null: false
      add :message, :text, null: false
      timestamps()
    end

    create index(:mail_messages, [:email])
    create index(:mail_messages, [:subject])
  end
end
