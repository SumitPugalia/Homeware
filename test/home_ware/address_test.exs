defmodule HomeWare.AddressTest do
  use HomeWare.DataCase

  alias HomeWare.Address
  alias HomeWare.Factory

  describe "address changeset" do
    test "changeset with valid attributes" do
      user = Factory.insert(:user)
      address = Factory.build(:address, %{user_id: user.id})
      changeset = Address.changeset(%Address{}, Map.from_struct(address))
      assert changeset.valid?
    end

    test "changeset with invalid address_type" do
      changeset = Address.changeset(%Address{}, %{address_type: :invalid})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).address_type
    end

    test "changeset with missing required fields" do
      changeset = Address.changeset(%Address{}, %{})
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :first_name)
      assert Map.has_key?(errors, :last_name)
      assert Map.has_key?(errors, :address_line_1)
      assert Map.has_key?(errors, :city)
      assert Map.has_key?(errors, :state)
      assert Map.has_key?(errors, :postal_code)
      assert Map.has_key?(errors, :country)
      assert Map.has_key?(errors, :user_id)
    end
  end
end
