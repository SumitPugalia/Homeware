defmodule HomeWareWeb.Admin.DashboardControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

  setup do
    admin_user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(HomeWare.Guardian, admin_user)

    %{admin_user: admin_user, token: token}
  end

  describe "dashboard" do
    test "GET /admin/dashboard shows dashboard with correct stats", %{conn: conn, token: token} do
      # Create some test data
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :admin, is_active: true})

      # Create some orders
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})
      Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})
      Factory.insert(:order, %{status: :pending, total_amount: Decimal.new("50.00")})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/dashboard")

      assert html_response(conn, 200) =~ "Dashboard"
      assert html_response(conn, 200) =~ "Total Products"
      assert html_response(conn, 200) =~ "Total Orders"
      assert html_response(conn, 200) =~ "Total Customers"
      assert html_response(conn, 200) =~ "Revenue"
    end

    test "GET /admin/dashboard requires admin access", %{conn: conn} do
      # Try to access without authentication
      conn = get(conn, ~p"/admin/dashboard")
      assert redirected_to(conn) =~ "/users/log_in"
    end

    test "GET /admin/dashboard denies access to non-admin users", %{conn: conn} do
      customer_user = Factory.insert(:user, %{role: :customer})
      {:ok, token, _claims} = Guardian.encode_and_sign(HomeWare.Guardian, customer_user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/admin/dashboard")

      assert redirected_to(conn) =~ "/"
    end
  end
end
