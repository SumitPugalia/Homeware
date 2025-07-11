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
end
