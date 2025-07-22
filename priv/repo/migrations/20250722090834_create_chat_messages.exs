defmodule HomeWare.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages, primary_key: true) do
      add :chat_room_id, references(:chat_rooms, on_delete: :delete_all), null: false
      add :sender_type, :string, null: false
      add :sender_id, :uuid, null: false
      add :body, :text, null: false
      timestamps()
    end

    create index(:chat_messages, [:chat_room_id])
    create index(:chat_messages, [:sender_id])
  end
end
