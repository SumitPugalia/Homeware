defmodule HomeWare.OrdersTest do
  use HomeWare.DataCase

  alias HomeWare.Orders
  alias HomeWare.Factory

  describe "orders" do
    alias HomeWare.Orders.Order

    test "list_user_orders/1 returns all orders for a user" do
      user = Factory.insert(:user)
      order = Factory.insert(:order, %{user_id: user.id})
      assert Orders.list_user_orders(user.id) == [order]
    end

    test "get_user_order!/2 returns the order with given id for user" do
      user = Factory.insert(:user)
      order = Factory.insert(:order, %{user_id: user.id})
      assert Orders.get_user_order!(user.id, order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      user = Factory.insert(:user)
      address = Factory.insert(:address, %{user_id: user.id})

      valid_attrs = %{
        order_number: "ORD-12345",
        status: :pending,
        subtotal: Decimal.new("100.00"),
        tax_amount: Decimal.new("8.00"),
        shipping_amount: Decimal.new("10.00"),
        discount_amount: Decimal.new("5.00"),
        total_amount: Decimal.new("113.00"),
        currency: "USD",
        notes: "Gift wrapped",
        user_id: user.id,
        shipping_address_id: address.id,
        billing_address_id: address.id
      }

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.order_number == "ORD-12345"
      assert order.status == :pending
      assert order.total_amount == Decimal.new("113.00")
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(%{order_number: nil})
    end

    test "update_order/2 with valid data updates the order" do
      order = Factory.insert(:order)
      update_attrs = %{status: :paid, notes: "Updated notes"}

      assert {:ok, %Order{} = updated_order} = Orders.update_order(order, update_attrs)
      assert updated_order.status == :paid
      assert updated_order.notes == "Updated notes"
    end

    test "calculate_total_revenue/0 returns sum of completed orders" do
      # Create orders with different statuses
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})
      Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})
      # should not be included
      Factory.insert(:order, %{status: :pending, total_amount: Decimal.new("50.00")})
      # should not be included
      Factory.insert(:order, %{status: :cancelled, total_amount: Decimal.new("25.00")})

      total_revenue = Orders.calculate_total_revenue()
      assert Decimal.eq?(total_revenue, Decimal.new("300.00"))
    end

    test "calculate_revenue_by_status/1 returns revenue for specific status" do
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("100.00")})
      Factory.insert(:order, %{status: :paid, total_amount: Decimal.new("150.00")})
      Factory.insert(:order, %{status: :delivered, total_amount: Decimal.new("200.00")})

      paid_revenue = Orders.calculate_revenue_by_status(:paid)
      assert Decimal.eq?(paid_revenue, Decimal.new("250.00"))

      delivered_revenue = Orders.calculate_revenue_by_status(:delivered)
      assert Decimal.eq?(delivered_revenue, Decimal.new("200.00"))
    end

    test "get_monthly_sales_data/1 returns monthly revenue data" do
      # Create an order for this month
      Factory.insert(:order, %{
        status: :delivered,
        total_amount: Decimal.new("500.00"),
        inserted_at: DateTime.truncate(DateTime.utc_now(), :second)
      })

      monthly_data = Orders.get_monthly_sales_data(1)
      assert length(monthly_data) == 1
      {_month, revenue} = List.first(monthly_data)
      assert revenue > 0.0
    end

    test "count_orders/0 returns total order count" do
      Factory.insert(:order)
      Factory.insert(:order)
      Factory.insert(:order)

      assert Orders.count_orders() == 3
    end

    test "count_orders_by_status/1 returns count for specific status" do
      Factory.insert(:order, %{status: :pending})
      Factory.insert(:order, %{status: :pending})
      Factory.insert(:order, %{status: :delivered})

      assert Orders.count_orders_by_status(:pending) == 2
      assert Orders.count_orders_by_status(:delivered) == 1
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = Factory.insert(:order)
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, %{order_number: nil})
      assert order == Orders.get_user_order!(order.user_id, order.id)
    end

    test "delete_order/1 deletes the order" do
      order = Factory.insert(:order)
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_user_order!(order.user_id, order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = Factory.insert(:order)
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end

  describe "calculate_subtotal/1" do
    test "handles cart items with nil price_override" do
      # Create a cart item with nil price_override
      cart_item = %{
        quantity: 2,
        product: %{selling_price: Decimal.new("10.00")},
        product_variant: %{price_override: nil}
      }

      # This should not raise an error
      result = Orders.calculate_subtotal([cart_item])
      assert Decimal.eq?(result, Decimal.new("20.00"))
    end

    test "handles cart items with valid price_override" do
      cart_item = %{
        quantity: 2,
        product: %{selling_price: Decimal.new("10.00")},
        product_variant: %{price_override: Decimal.new("15.00")}
      }

      result = Orders.calculate_subtotal([cart_item])
      assert Decimal.eq?(result, Decimal.new("30.00"))
    end

    test "handles cart items without product_variant" do
      cart_item = %{
        quantity: 2,
        product: %{selling_price: Decimal.new("10.00")}
      }

      result = Orders.calculate_subtotal([cart_item])
      assert Decimal.eq?(result, Decimal.new("20.00"))
    end
  end
end
