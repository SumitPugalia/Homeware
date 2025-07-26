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
       |> put_flash(:error, "You must be logged in to chat with customer support.")
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

  # Handle input changes
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message, message)}
  end

  # Handle send button click
  def handle_event("send_message", _params, socket) do
    message = socket.assigns.message

    if message && String.trim(message) != "" do
      user = socket.assigns.current_user
      chat_room = socket.assigns.chat_room

      {:ok, _msg} =
        Chat.create_message(%{
          chat_room_id: chat_room.id,
          sender_type: "customer",
          sender_id: user.id,
          body: message
        })

      PubSub.broadcast(HomeWare.PubSub, @topic, {:new_message, chat_room.id})
      {:noreply, assign(socket, :message, "")}
    else
      {:noreply, socket}
    end
  end

  # Handle Enter key press
  def handle_event("send_on_enter", _params, socket) do
    {:noreply, socket}
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
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-4">
      <div class="w-full max-w-4xl h-[85vh] bg-white dark:bg-gray-900 rounded-3xl shadow-2xl border border-gray-200 dark:border-gray-700 overflow-hidden flex flex-col">
        <!-- Chat Header -->
        <div class="bg-gradient-to-r from-purple-600 to-pink-600 px-6 py-4 flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
            </div>
            <div>
              <h2 class="text-xl font-bold text-white">Customer Support</h2>
              <p class="text-purple-100 text-sm">We're here to help you</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
            <span class="text-purple-100 text-sm font-medium">Online</span>
          </div>
        </div>
        <!-- Messages Container -->
        <div
          class="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-800 p-6 space-y-4"
          id="chat-messages"
          phx-hook="ChatScroll"
        >
          <%= if Enum.empty?(@messages) do %>
            <!-- Welcome Message -->
            <div class="flex justify-center">
              <div class="bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl p-6 max-w-md text-center shadow-lg">
                <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    class="w-8 h-8 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                    />
                  </svg>
                </div>
                <h3 class="text-lg font-bold text-white mb-2">Welcome to Customer Support!</h3>
                <p class="text-purple-100 text-sm leading-relaxed">
                  Hi <%= @current_user.first_name || "there" %>! 👋 How can we help you today?
                  Feel free to ask any questions about your orders, products, or anything else.
                </p>
              </div>
            </div>
          <% end %>

          <%= for msg <- @messages do %>
            <div class={
              [
                "flex w-full",
                if(msg.sender_type == "customer", do: "justify-end", else: "justify-start")
              ]
              |> Enum.join(" ")
            }>
              <div class={
                [
                  "max-w-[70%] lg:max-w-[60%]",
                  if(msg.sender_type == "customer", do: "order-2", else: "order-1")
                ]
                |> Enum.join(" ")
              }>
                <!-- Avatar -->
                <div class={
                  [
                    "flex items-end space-x-2",
                    if(msg.sender_type == "customer",
                      do: "flex-row-reverse space-x-reverse",
                      else: ""
                    )
                  ]
                  |> Enum.join(" ")
                }>
                  <div class={
                    [
                      "w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold",
                      if(msg.sender_type == "customer",
                        do: "bg-gradient-to-r from-purple-500 to-pink-500 text-white",
                        else: "bg-gradient-to-r from-gray-500 to-gray-600 text-white"
                      )
                    ]
                    |> Enum.join(" ")
                  }>
                    <%= if msg.sender_type == "customer" do %>
                      <%= String.first(@current_user.first_name || "U") %>
                    <% else %>
                      S
                    <% end %>
                  </div>
                  <!-- Message Bubble -->
                  <div class={
                    [
                      "rounded-2xl px-4 py-3 shadow-sm",
                      if(msg.sender_type == "customer",
                        do: "bg-gradient-to-r from-purple-500 to-pink-500 text-white",
                        else:
                          "bg-white dark:bg-gray-700 text-gray-900 dark:text-white border border-gray-200 dark:border-gray-600"
                      )
                    ]
                    |> Enum.join(" ")
                  }>
                    <p class="text-sm leading-relaxed break-words"><%= msg.body %></p>
                    <p class={
                      [
                        "text-xs mt-1",
                        if(msg.sender_type == "customer",
                          do: "text-purple-100",
                          else: "text-gray-500 dark:text-gray-400"
                        )
                      ]
                      |> Enum.join(" ")
                    }>
                      <%= Calendar.strftime(msg.inserted_at, "%I:%M %p") %>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        <!-- Message Input -->
        <div class="bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700 p-4">
          <form phx-submit="send_message" phx-change="update_message" class="flex items-end space-x-3">
            <div class="flex-1 relative">
              <input
                type="text"
                name="message"
                value={@message}
                placeholder="Type your message here..."
                class="w-full px-4 py-3 pr-12 bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-2xl text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all duration-200 resize-none"
                autocomplete="off"
                maxlength="500"
                id="message-input"
                phx-hook="AutoResize"
              />
              <div class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 text-xs">
                <%= String.length(@message || "") %>/500
              </div>
            </div>
            <button
              type="submit"
              disabled={!@message || String.trim(@message) == ""}
              class="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 disabled:from-gray-400 disabled:to-gray-500 text-white px-6 py-3 rounded-2xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:scale-100 disabled:cursor-not-allowed shadow-lg hover:shadow-xl flex items-center space-x-2"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                />
              </svg>
              <span>Send</span>
            </button>
          </form>
        </div>
      </div>
    </div>

    <script>
      // Auto-resize textarea
      window.addEventListener('phx:update', () => {
        const textarea = document.querySelector('input[name="message"]');
        if (textarea) {
          textarea.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';
          });
        }
      });

      // Auto-scroll to bottom
      window.addEventListener('phx:update', () => {
        const chatMessages = document.getElementById('chat-messages');
        if (chatMessages) {
          chatMessages.scrollTop = chatMessages.scrollHeight;
        }
      });
    </script>
    """
  end
end
