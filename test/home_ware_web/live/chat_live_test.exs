defmodule HomeWareWeb.ChatLiveTest do
  use HomeWareWeb.LiveViewCase, async: true
  import HomeWare.Factory

  describe "Chat UI" do
    setup %{conn: conn} do
      user = insert(:user)
      {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(user)
      conn = Phoenix.ConnTest.init_test_session(conn, user_token: token)
      %{conn: conn, user: user}
    end

    test "renders chat UI elements", %{conn: conn, user: user} do
      _chat_room = insert(:chat_room, %{customer_id: user.id})
      {:ok, lv, _html} = live(conn, "/chat")

      # Check initial UI elements
      assert has_element?(lv, "h2", "Customer Support")
      assert has_element?(lv, "input[name=message]")
      assert has_element?(lv, "button", "Send")
      assert has_element?(lv, "form[phx-submit=send_message]")
    end

    test "renders chat UI with existing messages", %{conn: conn, user: user} do
      chat_room = insert(:chat_room, %{customer_id: user.id})

      # Create a message directly in the database
      _message =
        insert(:chat_message, %{
          chat_room_id: chat_room.id,
          sender_type: "customer",
          sender_id: user.id,
          body: "Test message from database"
        })

      {:ok, lv, _html} = live(conn, "/chat")

      # Check that the existing message is displayed
      assert render(lv) =~ "Test message from database"
    end

    test "shows welcome message when no messages exist", %{conn: conn, user: user} do
      _chat_room = insert(:chat_room, %{customer_id: user.id})
      {:ok, lv, _html} = live(conn, "/chat")

      # Check that welcome message is displayed
      assert render(lv) =~ "Welcome to Customer Support"
      assert render(lv) =~ "How can we help you today"
    end

    test "can send a message and it appears in the chat", %{conn: conn, user: user} do
      chat_room = insert(:chat_room, %{customer_id: user.id})
      {:ok, lv, _html} = live(conn, "/chat")

      # Submit a message
      msg = "Hello, this is a test!"

      lv
      |> form("form[phx-submit=send_message]", message: msg)
      |> render_submit()

      # Wait for the LiveView to process the message
      Process.sleep(500)

      # Check if the message was created in the database
      messages = HomeWare.Chat.list_messages(chat_room.id)
      assert length(messages) == 1
      assert hd(messages).body == msg
      assert hd(messages).sender_type == "customer"
      assert hd(messages).sender_id == user.id

      # Check if the message appears in the rendered HTML
      assert render(lv) =~ msg
    end
  end
end
