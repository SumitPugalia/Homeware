defmodule HomeWare.Chat do
  @moduledoc """
  The Chat context for admin-customer messaging.
  """
  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Chat.ChatRoom
  alias HomeWare.Chat.ChatMessage

  def list_rooms_for_user(user_id) do
    ChatRoom |> where([r], r.customer_id == ^user_id) |> Repo.all()
  end

  def list_rooms_for_admin do
    ChatRoom |> Repo.all()
  end

  def get_room!(id), do: Repo.get!(ChatRoom, id)

  def list_messages(room_id) do
    ChatMessage
    |> where([m], m.chat_room_id == ^room_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  def create_room(attrs) do
    %ChatRoom{} |> ChatRoom.changeset(attrs) |> Repo.insert()
  end

  def create_message(attrs) do
    %ChatMessage{} |> ChatMessage.changeset(attrs) |> Repo.insert()
  end
end
