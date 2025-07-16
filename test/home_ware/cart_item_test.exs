defmodule HomeWare.CartItemTest do
  use HomeWare.DataCase

  alias HomeWare.CartItem
  alias HomeWare.Factory

  describe "cart_item changeset" do
    test "changeset with valid attributes" do
      cart_item = Factory.build(:cart_item)
      changeset = CartItem.changeset(%CartItem{}, Map.from_struct(cart_item))
      assert changeset.valid?
    end

    test "changeset with invalid quantity" do
      changeset = CartItem.changeset(%CartItem{}, %{quantity: 0})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).quantity
    end

    test "changeset with missing required fields" do
      changeset = CartItem.changeset(%CartItem{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).quantity
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).product_id
    end
  end
end
