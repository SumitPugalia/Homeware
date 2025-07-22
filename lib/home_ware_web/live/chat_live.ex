defmodule HomeWareWeb.ChatLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}
  alias HomeWare.Chat
  alias HomeWare.Chat.ChatMessage
  alias Phoenix.PubSub

  @topic "chat:admin_customer"

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case HomeWare.Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          {:error, _reason} -> nil
        end
    end
  end

  def mount(_params, session, socket) do
    user = get_user_from_session(session)

    if is_nil(user) do
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to chat with admin.")
       |> push_navigate(to: "/users/log_in")}
    else
      if connected?(socket), do: PubSub.subscribe(HomeWare.PubSub, @topic)

      chat_room =
        Chat.list_rooms_for_user(user.id)
        |> List.first() ||
          with {:ok, room} <- Chat.create_room(%{customer_id: user.id, status: "open"}), do: room

      messages = Chat.list_messages(chat_room.id)

      {:ok,
       socket
       |> assign(:current_user, user)
       |> assign(:chat_room, chat_room)
       |> assign(:messages, messages)
       |> assign(:message, "")}
    end
  end

  def handle_event("send_message", %{"message" => body}, socket) do
    user = socket.assigns.current_user
    chat_room = socket.assigns.chat_room

    {:ok, _msg} =
      Chat.create_message(%{
        chat_room_id: chat_room.id,
        sender_type: "customer",
        sender_id: user.id,
        body: body
      })

    PubSub.broadcast(HomeWare.PubSub, @topic, {:new_message, chat_room.id})
    {:noreply, assign(socket, :message, "")}
  end

  def handle_info({:new_message, room_id}, socket) do
    if socket.assigns.chat_room.id == room_id do
      messages = Chat.list_messages(room_id)
      {:noreply, assign(socket, :messages, messages)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-4 bg-white rounded shadow">
      <h2 class="text-lg font-bold mb-2">Chat with Admin</h2>
      <div class="h-64 overflow-y-auto bg-gray-100 rounded p-2 mb-2">
        <%= for msg <- @messages do %>
          <div class={if msg.sender_type == "customer", do: "text-right", else: "text-left"}>
            <span class={[
              if(msg.sender_type == "customer", do: "bg-blue-200", else: "bg-gray-300"),
              "inline-block rounded px-2 py-1 my-1"
            ]}>
              <%= msg.body %>
            </span>
          </div>
        <% end %>
      </div>
      <form phx-submit="send_message" class="flex gap-2">
        <input
          type="text"
          name="message"
          value={@message}
          placeholder="Type your message..."
          class="flex-1 rounded border px-2"
          autocomplete="off"
        />
        <button type="submit" class="bg-blue-500 text-white px-4 py-1 rounded">Send</button>
      </form>
    </div>
    """
  end
end
