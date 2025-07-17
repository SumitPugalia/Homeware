defmodule HomeWareWeb.Admin.DashboardLiveTest do
  use HomeWareWeb.LiveViewCase

  alias HomeWare.Factory

  setup do
    admin_user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(HomeWare.Guardian, admin_user)

    %{admin_user: admin_user, token: token}
  end

  describe "dashboard live" do
    test "shows dashboard with real-time stats", %{conn: conn, token: token} do
      # Create some test data
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :admin, is_active: true})

      # Create some orders
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})
      Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})
      Factory.insert(:order, %{status: :pending, total_amount: Decimal.new("50.00")})

      # Create some products
      Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      Factory.insert(:product, %{is_active: true, inventory_quantity: 5})

      # Connect to the dashboard
      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that the dashboard loads with stats
      assert has_element?(view, "h1", "Admin Dashboard")
      assert has_element?(view, "button", "Refresh")

      # Check that stats are displayed
      assert has_element?(view, "dt", "Total Revenue")
      assert has_element?(view, "dt", "Total Orders")
      assert has_element?(view, "dt", "Active Orders")
      assert has_element?(view, "dt", "Total Customers")
    end

    test "refresh button updates stats", %{conn: conn, token: token} do
      # Create initial data
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})

      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Get initial stats
      _initial_revenue = view |> element("dt", "Total Revenue") |> render()
      _initial_orders = view |> element("dt", "Total Orders") |> render()

      # Add more data
      Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})
      Factory.insert(:user, %{role: :customer, is_active: true})

      # Click refresh
      view |> element("button", "Refresh") |> render_click()

      # Check that stats are updated
      assert has_element?(view, "dd", "₹300.00")
      assert has_element?(view, "dd", "2")
      # customers
      assert has_element?(view, "dd", "2")
    end

    test "shows recent orders section", %{conn: conn, token: token} do
      # Create some orders
      _order1 = Factory.insert(:order, %{status: :pending, total_amount: Decimal.new("100.00")})
      _order2 = Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})

      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that recent orders section is present
      assert has_element?(view, "h3", "Recent Orders")
      assert has_element?(view, "span", "Pending")
      assert has_element?(view, "span", "Delivered")
    end

    test "shows best sellers section", %{conn: conn, token: token} do
      # Create some products
      Factory.insert(:product, %{name: "Product 1", is_active: true, inventory_quantity: 10})
      Factory.insert(:product, %{name: "Product 2", is_active: true, inventory_quantity: 5})

      {:ok, view, _html} =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
        |> live("/admin/dashboard")

      # Check that best sellers section is present
      assert has_element?(view, "h3", "Best Sellers")
      assert has_element?(view, "span", "Best Seller")
    end
  end
end
