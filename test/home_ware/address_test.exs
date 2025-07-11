defmodule HomeWare.AddressTest do
  use HomeWare.DataCase

  alias HomeWare.Address
  alias HomeWare.Factory

  describe "address changeset" do
    test "changeset with valid attributes" do
      address = Factory.build(:address)
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
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).address_type
      assert "can't be blank" in errors_on(changeset).first_name
      assert "can't be blank" in errors_on(changeset).last_name
      assert "can't be blank" in errors_on(changeset).address_line_1
      assert "can't be blank" in errors_on(changeset).city
      assert "can't be blank" in errors_on(changeset).state
      assert "can't be blank" in errors_on(changeset).postal_code
      assert "can't be blank" in errors_on(changeset).country
    end
  end
end
