defmodule HomeWareWeb.OrderControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

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
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/orders")
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
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/orders/#{order.id}")
      assert html_response(conn, 200) =~ "Order Details"
    end
  end

  defp log_in_user(conn, user) do
    conn
    |> post(~p"/users/log_in", %{
      "user" => %{"email" => user.email, "password" => "password123"}
    })
  end
end
