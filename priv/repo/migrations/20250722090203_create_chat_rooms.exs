defmodule HomeWare.Repo.Migrations.CreateChatRooms do
  use Ecto.Migration

  def change do
    create table(:chat_rooms, primary_key: true) do
      add :customer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :admin_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :status, :string, default: "open", null: false
      timestamps()
    end

    create index(:chat_rooms, [:customer_id])
    create index(:chat_rooms, [:admin_id])
  end
end
