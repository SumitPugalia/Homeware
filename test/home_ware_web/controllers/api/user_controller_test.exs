defmodule HomeWareWeb.Api.UserControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup do
    user = Factory.insert(:user)
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    %{user: user, token: token}
  end

  describe "GET /api/profile" do
    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/api/profile")
      assert json_response(conn, 401)
    end

    test "returns user profile when authenticated", %{conn: conn, user: user, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/profile")

      response = json_response(conn, 200)
      assert response["user"]["id"] == user.id
      assert response["user"]["email"] == user.email
      assert response["user"]["first_name"] == user.first_name
      assert response["user"]["last_name"] == user.last_name
    end
  end
end
