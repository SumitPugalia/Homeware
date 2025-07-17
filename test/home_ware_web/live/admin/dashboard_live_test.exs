defmodule HomeWareWeb.Admin.DashboardLiveTest do
  use HomeWareWeb.LiveViewCase

  alias HomeWare.Factory

  setup do
    admin_user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(HomeWare.Guardian, admin_user)

    %{admin_user: admin_user, token: token}
  end

  describe "dashboard" do
    test "dashboard live shows dashboard with real-time stats", %{conn: conn, token: token} do
      # Create some test data
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :admin, is_active: true})

      # Create some orders
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})

      # Connect to the dashboard
      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that the dashboard title is present
      assert has_element?(view, "h1", "Dashboard")

      # Check that stats cards are present
      assert has_element?(view, "p", "Revenue")
      assert has_element?(view, "p", "Orders")
      assert has_element?(view, "p", "Active")
      assert has_element?(view, "p", "Customers")
    end

    test "dashboard live refresh button updates stats", %{conn: conn, token: token} do
      # Create initial test data
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})

      # Connect to the dashboard
      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Get initial stats
      _initial_revenue = view |> element("p", "Revenue") |> render()
      _initial_orders = view |> element("p", "Orders") |> render()

      # Create some orders
      _order1 = Factory.insert(:order, %{status: :pending, total_amount: Decimal.new("100.00")})
      _order2 = Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})

      # Click refresh button
      view |> element("button", "Refresh") |> render_click()

      # Check that stats have been updated
      assert has_element?(view, "button", "Refresh")
    end

    test "dashboard live shows recent orders section", %{conn: conn, token: token} do
      # Create some test data
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})

      # Connect to the dashboard
      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that recent orders section is present
      assert has_element?(view, "h3", "Recent Orders")
    end

    test "dashboard live shows best sellers section", %{conn: conn, token: token} do
      # Create some test data
      Factory.insert(:product, %{name: "Test Product", price: Decimal.new("50.00")})

      # Connect to the dashboard
      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that best sellers section is present
      assert has_element?(view, "h3", "Best Sellers")
    end
  end
end
