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
  def handle_event("send_message", %{"message" => message}, socket) do
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
    <div class="h-screen bg-gradient-to-br from-brand-neutral-50 to-white flex flex-col">
      <!-- Chat Header -->
      <div class="bg-white border-b border-brand-neutral-200 shadow-sm flex-shrink-0">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <div class="flex items-center space-x-4">
              <a href="/" class="text-2xl font-bold text-brand-primary">HomeWare</a>
              <span class="text-brand-neutral-400">/</span>
              <span class="text-text-primary font-medium">Customer Support</span>
            </div>
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-brand-accent rounded-full animate-pulse"></div>
                <span class="text-brand-accent text-sm font-medium">Online</span>
              </div>
              <a href="/" class="text-text-secondary hover:text-brand-primary transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
      <!-- Chat Container -->
      <div class="flex-1 flex flex-col max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-6 overflow-hidden">
        <!-- Support Info Card -->
        <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 p-4 mb-4 flex-shrink-0">
          <div class="flex items-center space-x-3">
            <div class="w-10 h-10 bg-brand-primary/10 rounded-full flex items-center justify-center">
              <svg
                class="w-5 h-5 text-brand-primary"
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
            <div class="flex-1">
              <h2 class="text-base font-semibold text-text-primary">Customer Support</h2>
              <p class="text-text-secondary text-xs">
                We're here to help you with any questions or concerns
              </p>
            </div>
            <div class="flex items-center space-x-2 text-brand-accent">
              <div class="w-2 h-2 bg-brand-accent rounded-full animate-pulse"></div>
              <span class="text-xs font-medium">Available 24/7</span>
            </div>
          </div>
        </div>
        <!-- Messages Container -->
        <div class="flex-1 bg-white rounded-xl shadow-sm border border-brand-neutral-200 overflow-hidden flex flex-col min-h-0">
          <!-- Messages Area -->
          <div
            class="flex-1 overflow-y-auto p-4 space-y-2 bg-brand-neutral-50/30"
            id="chat-messages"
            phx-hook="ChatScroll"
          >
            <%= if Enum.empty?(@messages) do %>
              <!-- Welcome Message -->
              <div class="flex justify-center">
                <div class="bg-white rounded-lg p-6 max-w-sm text-center shadow-sm border border-brand-neutral-200">
                  <div class="w-12 h-12 bg-brand-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
                    <svg
                      class="w-6 h-6 text-brand-primary"
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
                  <h3 class="text-lg font-semibold text-text-primary mb-2">
                    Welcome to Customer Support!
                  </h3>
                  <p class="text-text-secondary text-xs leading-relaxed">
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
                    "max-w-[80%] lg:max-w-[70%]",
                    if(msg.sender_type == "customer", do: "order-2", else: "order-1")
                  ]
                  |> Enum.join(" ")
                }>
                  <!-- Message Container -->
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
                    <!-- Avatar -->
                    <div class={
                      [
                        "w-6 h-6 rounded-full flex items-center justify-center text-xs font-semibold flex-shrink-0",
                        if(msg.sender_type == "customer",
                          do: "bg-brand-primary text-white",
                          else: "bg-brand-neutral-200 text-brand-neutral-700"
                        )
                      ]
                      |> Enum.join(" ")
                    }>
                      <%= if msg.sender_type == "customer" do %>
                        <%= String.first(@current_user.first_name || "U") %>
                      <% else %>
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                          />
                        </svg>
                      <% end %>
                    </div>
                    <!-- Message Bubble -->
                    <div class={
                      [
                        "rounded-lg px-3 py-2 shadow-sm",
                        if(msg.sender_type == "customer",
                          do: "bg-brand-primary text-white",
                          else: "bg-white text-text-primary border border-brand-neutral-200"
                        )
                      ]
                      |> Enum.join(" ")
                    }>
                      <p class="text-xs leading-relaxed break-words"><%= msg.body %></p>
                      <p class={
                        [
                          "text-xs mt-1",
                          if(msg.sender_type == "customer",
                            do: "text-brand-primary/80",
                            else: "text-text-secondary"
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
          <div class="bg-white border-t border-brand-neutral-200 p-3 flex-shrink-0">
            <form
              phx-submit="send_message"
              phx-change="update_message"
              class="flex items-end space-x-2"
            >
              <div class="flex-1 relative">
                <input
                  type="text"
                  name="message"
                  value={@message}
                  placeholder="Type your message here..."
                  class="w-full px-3 py-2 pr-12 bg-brand-neutral-50 border border-brand-neutral-300 rounded-lg text-text-primary placeholder-brand-neutral-400 focus:outline-none focus:ring-2 focus:ring-brand-primary/20 focus:border-brand-primary transition-all duration-200 resize-none text-sm"
                  autocomplete="off"
                  maxlength="500"
                  id="message-input"
                  phx-hook="AutoResize"
                />
                <div class="absolute right-2 top-1/2 transform -translate-y-1/2 text-brand-neutral-400 text-xs">
                  <%= String.length(@message || "") %>/500
                </div>
              </div>
              <button
                type="submit"
                disabled={!@message || String.trim(@message) == ""}
                class="bg-brand-primary hover:bg-brand-primary-hover disabled:bg-brand-neutral-200 disabled:text-brand-neutral-400 text-white px-4 py-2 rounded-lg font-medium transition-all duration-200 transform hover:scale-105 disabled:scale-100 disabled:cursor-not-allowed shadow-sm hover:shadow-md flex items-center space-x-2 text-sm"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
    </div>

    <script>
      // Auto-resize textarea
      window.addEventListener('phx:update', () => {
        const textarea = document.querySelector('input[name="message"]');
        if (textarea) {
          textarea.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 80) + 'px';
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
