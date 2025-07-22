defmodule HomeWare.Chat.ChatRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_rooms" do
    belongs_to :customer, HomeWare.Accounts.User, type: :binary_id
    belongs_to :admin, HomeWare.Accounts.User, type: :binary_id
    field :status, :string, default: "open"
    has_many :messages, HomeWare.Chat.ChatMessage
    timestamps()
  end

  def changeset(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:customer_id, :admin_id, :status])
    |> validate_required([:customer_id, :status])
  end
end
