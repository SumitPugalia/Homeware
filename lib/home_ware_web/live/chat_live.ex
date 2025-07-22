defmodule HomeWareWeb.ChatLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}
  alias HomeWare.Chat
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
    <div class="flex justify-center items-center min-h-[80vh] bg-transparent px-2 sm:px-0">
      <div class="w-full max-w-lg sm:max-w-md md:max-w-lg bg-gray-900 rounded-xl shadow-lg flex flex-col h-[80vh] sm:h-[70vh] border border-gray-800">
        <h2 class="text-lg font-bold mb-2 px-4 pt-4 pb-2 border-b border-gray-800 text-white">
          Chat with Admin
        </h2>
        <div class="flex-1 overflow-y-auto px-2 py-2 space-y-1" id="chat-messages">
          <%= for msg <- @messages do %>
            <div class={
              [
                "flex w-full",
                if(msg.sender_type == "customer", do: "justify-end", else: "justify-start")
              ]
              |> Enum.join(" ")
            }>
              <span class={
                [
                  if(msg.sender_type == "customer",
                    do: "bg-blue-400 text-gray-900",
                    else: "bg-gray-100 text-gray-900"
                  ),
                  "inline-block rounded-2xl px-4 py-2 my-1 max-w-[80%] text-sm shadow-md break-words"
                ]
                |> Enum.join(" ")
              }>
                <%= msg.body %>
              </span>
            </div>
          <% end %>
        </div>
        <form
          phx-submit="send_message"
          class="flex gap-2 p-2 border-t border-gray-800 bg-gray-900 sticky bottom-0 z-10"
        >
          <input
            type="text"
            name="message"
            value={@message}
            placeholder="Type your message..."
            class="flex-1 rounded-full border border-gray-700 bg-gray-800 text-white px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400 text-sm placeholder-gray-400"
            autocomplete="off"
            maxlength="500"
          />
          <button
            type="submit"
            class="bg-blue-400 hover:bg-blue-500 text-gray-900 px-5 py-2 rounded-full font-semibold transition-colors text-sm shadow"
          >
            Send
          </button>
        </form>
      </div>
    </div>
    <style>
      @media (max-width: 640px) {
        #chat-messages { min-height: 50vh; max-height: 60vh; }
      }
    </style>
    """
  end
end
