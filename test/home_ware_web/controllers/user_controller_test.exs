defmodule HomeWareWeb.UserControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

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
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/profile")

      assert html_response(conn, 200) =~ "Profile"
    end
  end
end
