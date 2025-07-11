defmodule HomeWareWeb.OrderControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup %{conn: conn} do
    %{conn: conn}
  end

  describe "index" do
    test "GET /orders redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/orders")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /orders shows orders when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/orders")

      assert html_response(conn, 200) =~ "Orders"
    end
  end

  describe "show" do
    test "GET /orders/:id redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/orders/1")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /orders/:id shows order when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      order = Factory.insert(:order, %{user_id: user.id})
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/orders/#{order.id}")

      assert html_response(conn, 200) =~ "Order Details"
    end
  end
end
