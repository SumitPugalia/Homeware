defmodule HomeWareWeb.RouterTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

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
      assert html_response(conn, 200) =~ "Create your account"
    end

    test "GET /users/log_in", %{conn: conn} do
      conn = get(conn, ~p"/users/log_in")
      assert html_response(conn, 200) =~ "Sign in to your account"
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
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/profile")

      assert html_response(conn, 200) =~ "Profile"
    end

    test "GET /orders works when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/orders")

      assert html_response(conn, 200) =~ "Orders"
    end

    test "GET /admin/dashboard works when authenticated as admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :admin})
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/dashboard")

      assert html_response(conn, 200) =~ "Admin Dashboard"
    end
  end

  describe "API routes" do
    test "GET /api/products works without authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/products")
      assert json_response(conn, 200)
    end

    test "GET /api/profile requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/profile")
      assert json_response(conn, 401)
    end

    test "GET /api/profile works with valid token", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/profile")

      response = json_response(conn, 200)
      assert response["user"]["id"] == user.id
    end
  end
end
