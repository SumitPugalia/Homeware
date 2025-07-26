defmodule HomeWareWeb.Admin.ChatLive do
  use Phoenix.LiveView,
    layout: {HomeWareWeb.Layouts, :admin}

  use HomeWareWeb, :verified_routes
  alias HomeWare.Chat
  alias Phoenix.PubSub

  @topic "chat:admin_customer"

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(HomeWare.PubSub, @topic)
    rooms = Chat.list_rooms_for_admin() |> HomeWare.Repo.preload(:customer)
    room = List.first(rooms)
    messages = if room, do: Chat.list_messages(room.id), else: []

    {:ok,
     socket
     |> assign(:rooms, rooms)
     |> assign(:selected_room, room)
     |> assign(:messages, messages)
     |> assign(:message, "")
     |> assign(:current_path, "/admin/chat")}
  end

  def handle_event("select_room", %{"room_id" => room_id}, socket) do
    room = Chat.get_room!(room_id) |> HomeWare.Repo.preload(:customer)
    messages = Chat.list_messages(room.id)
    {:noreply, assign(socket, selected_room: room, messages: messages, message: "")}
  end

  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message, message)}
  end

  def handle_event("send_message", %{"message" => body}, socket) do
    room = socket.assigns.selected_room
    # TODO: set current admin id from session
    admin_id = nil

    {:ok, _msg} =
      Chat.create_message(%{
        chat_room_id: room.id,
        sender_type: "admin",
        sender_id: admin_id || Ecto.UUID.generate(),
        body: body
      })

    PubSub.broadcast(HomeWare.PubSub, @topic, {:new_message, room.id})
    {:noreply, assign(socket, :message, "")}
  end

  def handle_info({:new_message, room_id}, socket) do
    if socket.assigns.selected_room && socket.assigns.selected_room.id == room_id do
      messages = Chat.list_messages(room_id)
      {:noreply, assign(socket, :messages, messages)}
    else
      {:noreply, socket}
    end
  end

  defp latest_message_preview(room) do
    msg = Chat.list_messages(room.id) |> List.last()
    if msg, do: String.slice(msg.body, 0, 30), else: "No messages yet"
  end

  defp unread_count(room) do
    # Unread = messages from customer after last admin message
    msgs = Chat.list_messages(room.id)
    last_admin_idx = Enum.find_index(Enum.reverse(msgs), &(&1.sender_type == "admin"))

    customer_msgs =
      if last_admin_idx do
        Enum.reverse(msgs)
        |> Enum.take(last_admin_idx)
        |> Enum.filter(&(&1.sender_type == "customer"))
      else
        Enum.filter(msgs, &(&1.sender_type == "customer"))
      end

    length(customer_msgs)
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-[80vh] w-full bg-white rounded shadow gap-4">
      <div class="w-80 border-r pr-2 bg-gray-50 rounded-l-xl flex flex-col min-h-[80vh]">
        <h2 class="font-bold mb-2 px-2 pt-2">Customer Chats</h2>
        <ul class="flex-1 overflow-y-auto">
          <%= for room <- @rooms do %>
            <li class={"mb-1 px-2 py-2 rounded cursor-pointer hover:bg-blue-100 " <> if @selected_room && @selected_room.id == room.id, do: "bg-blue-100 font-bold", else: ""}>
              <button
                phx-click="select_room"
                phx-value-room_id={room.id}
                class="w-full text-left flex flex-col gap-0.5 relative"
              >
                <span class="truncate text-sm text-gray-800">
                  <%= if room.customer do %>
                    <%= room.customer.email %>
                  <% else %>
                    Customer: <%= room.customer_id %>
                  <% end %>
                </span>
                <span class="text-xs text-gray-500 truncate">
                  <%= latest_message_preview(room) %>
                </span>
                <%= if unread_count(room) > 0 do %>
                  <span class="absolute right-2 top-2 bg-red-500 text-white text-xs rounded-full px-2 py-0.5">
                    <%= unread_count(room) %>
                  </span>
                <% end %>
              </button>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="flex-1 flex flex-col min-h-[80vh]">
        <h2 class="font-bold mb-2">Chat</h2>
        <div class="flex-1 flex flex-col justify-end">
          <div class="overflow-y-auto flex-1 px-2 pb-2" id="chat-messages">
            <%= for msg <- @messages do %>
              <div class={
                if msg.sender_type == "admin", do: "flex justify-end", else: "flex justify-start"
              }>
                <span class={[
                  if(msg.sender_type == "admin",
                    do: "bg-green-200 text-gray-900",
                    else: "bg-gray-200 text-gray-900"
                  ),
                  "inline-block rounded px-3 py-2 my-1 max-w-[70%] text-sm shadow"
                ]}>
                  <%= msg.body %>
                </span>
              </div>
            <% end %>
          </div>
          <%= if @selected_room do %>
            <form
              phx-submit="send_message"
              phx-change="update_message"
              class="flex gap-2 border-t pt-2 bg-white sticky bottom-0 z-10"
            >
              <input
                type="text"
                name="message"
                value={@message}
                placeholder="Type your message..."
                class="flex-1 rounded border px-2 py-2"
                autocomplete="off"
              />
              <button
                type="submit"
                disabled={!@message || String.trim(@message) == ""}
                class="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white px-4 py-2 rounded transition-colors"
              >
                Send
              </button>
            </form>
          <% else %>
            <div class="text-gray-500">Select a chat room to start chatting.</div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
