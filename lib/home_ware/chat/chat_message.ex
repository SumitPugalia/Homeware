defmodule HomeWare.Chat.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    belongs_to :chat_room, HomeWare.Chat.ChatRoom
    field :sender_type, :string
    field :sender_id, :binary_id
    field :body, :string
    timestamps()
  end

  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:chat_room_id, :sender_type, :sender_id, :body])
    |> validate_required([:chat_room_id, :sender_type, :sender_id, :body])
  end
end
