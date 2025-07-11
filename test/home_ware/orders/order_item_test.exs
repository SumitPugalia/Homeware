defmodule HomeWare.Orders.OrderItemTest do
  use HomeWare.DataCase

  alias HomeWare.Orders.OrderItem
  alias HomeWare.Factory

  describe "order_item changeset" do
    test "changeset with valid attributes" do
      order_item = Factory.build(:order_item)
      changeset = OrderItem.changeset(%OrderItem{}, Map.from_struct(order_item))
      assert changeset.valid?
    end

    test "changeset with invalid quantity" do
      changeset = OrderItem.changeset(%OrderItem{}, %{quantity: 0})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).quantity
    end

    test "changeset with invalid unit_price" do
      changeset = OrderItem.changeset(%OrderItem{}, %{unit_price: Decimal.new("-10.00")})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).unit_price
    end

    test "changeset with invalid total_price" do
      changeset = OrderItem.changeset(%OrderItem{}, %{total_price: Decimal.new("-20.00")})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).total_price
    end

    test "changeset with missing required fields" do
      changeset = OrderItem.changeset(%OrderItem{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).quantity
      assert "can't be blank" in errors_on(changeset).unit_price
      assert "can't be blank" in errors_on(changeset).total_price
    end
  end
end
