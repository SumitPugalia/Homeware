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

    test "renders chat UI and allows sending a message", %{conn: conn, user: user} do
      _chat_room = insert(:chat_room, %{customer_id: user.id})
      {:ok, lv, _html} = live(conn, "/chat")

      assert has_element?(lv, "h2", "Customer Support")
      assert has_element?(lv, "input[name=message]")
      assert has_element?(lv, "button", "Send")

      # Simulate sending a message
      msg = "Hello, this is a test!"

      lv
      |> form("form[phx-submit=send_message]", message: msg)
      |> render_submit()

      assert render(lv) =~ msg
    end
  end
end
