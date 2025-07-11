defmodule HomeWareWeb.RouterTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

  describe "public routes" do
    test "GET /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "HomeWare"
    end

    test "GET /products", %{conn: conn} do
      conn = get(conn, ~p"/products")
      assert html_response(conn, 200) =~ "Product Catalog"
    end

    test "GET /users/register", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert html_response(conn, 200) =~ "Register"
    end

    test "GET /users/log_in", %{conn: conn} do
      conn = get(conn, ~p"/users/log_in")
      assert html_response(conn, 200) =~ "Log in"
    end
  end

  describe "protected routes" do
    test "GET /profile redirects when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /orders redirects when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/orders")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /admin/dashboard redirects when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/admin/dashboard")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /profile works when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/profile")
      assert html_response(conn, 200) =~ "Profile"
    end

    test "GET /orders works when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/orders")
      assert html_response(conn, 200) =~ "Orders"
    end

    test "GET /admin/dashboard works when authenticated as admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :admin})
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/admin/dashboard")
      assert html_response(conn, 200) =~ "Admin Dashboard"
    end
  end

  defp log_in_user(conn, user) do
    conn
    |> post(~p"/users/log_in", %{
      "user" => %{"email" => user.email, "password" => "password123"}
    })
  end
end
