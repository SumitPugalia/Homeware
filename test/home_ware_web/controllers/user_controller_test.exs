defmodule HomeWareWeb.UserControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

  setup %{conn: conn} do
    %{conn: conn}
  end

  describe "profile" do
    test "GET /profile redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /profile shows profile when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/profile")
      assert html_response(conn, 200) =~ "Profile"
    end
  end

  defp log_in_user(conn, user) do
    conn
    |> post(~p"/users/log_in", %{
      "user" => %{"email" => user.email, "password" => "password123"}
    })
  end
end
