defmodule HomeWareWeb.Admin.CSRFTest do
  use HomeWareWeb.ConnCase

  setup do
    admin_user = HomeWare.Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(admin_user)
    %{admin_user: admin_user, token: token}
  end

  describe "CSRF token validation" do
    test "admin dashboard loads with CSRF token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/dashboard")

      assert html_response(conn, 200) =~ "csrf-token"
      assert html_response(conn, 200) =~ "Admin Panel"
    end

    test "admin products index loads with CSRF token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/products")

      assert html_response(conn, 200) =~ "csrf-token"
      assert html_response(conn, 200) =~ "Products"
    end

    test "admin orders index loads with CSRF token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/orders")

      assert html_response(conn, 200) =~ "csrf-token"
      assert html_response(conn, 200) =~ "Orders"
    end

    test "logout form has CSRF token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/dashboard")

      response = html_response(conn, 200)
      assert response =~ "_csrf_token"
      assert response =~ "/users/log_out"
    end

    test "product delete form has CSRF token", %{conn: conn, token: token} do
      # Create a product first
      product = HomeWare.Factory.insert(:product)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/products/#{product.id}/confirm_delete")

      response = html_response(conn, 200)
      assert response =~ "_csrf_token"
      assert response =~ "Delete Product"
    end

    test "order status update form has CSRF token", %{conn: conn, token: token} do
      # Create an order first
      order = HomeWare.Factory.insert(:order)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/orders/#{order.id}")

      response = html_response(conn, 200)
      assert response =~ "_csrf_token"
      assert response =~ "Update Status"
    end
  end

  describe "CSRF token functionality" do
    test "logout works with valid CSRF token", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/users/log_out")

      assert redirected_to(conn) == ~p"/"
    end

    test "product deletion works with valid CSRF token", %{conn: conn, token: token} do
      product = HomeWare.Factory.insert(:product)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/admin/products/#{product.id}")

      assert redirected_to(conn) == ~p"/admin/products"
    end

    test "order status update works with valid CSRF token", %{conn: conn, token: token} do
      order = HomeWare.Factory.insert(:order)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/admin/orders/#{order.id}/update_status", %{status: "shipped"})

      assert redirected_to(conn) == ~p"/admin/orders/#{order.id}"
    end
  end
end
