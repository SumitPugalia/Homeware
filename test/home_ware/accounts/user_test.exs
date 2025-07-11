defmodule HomeWare.Accounts.UserTest do
  use HomeWare.DataCase

  alias HomeWare.Accounts.User

  describe "user changeset" do
    test "changeset with valid attributes" do
      valid_attrs = %{
        email: "test@example.com",
        hashed_password: "hashed_password_123",
        first_name: "John",
        last_name: "Doe",
        role: :customer
      }

      changeset = User.changeset(%User{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid email" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: "invalid-email",
          password: "testpassword123"
        })

      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "changeset with short password" do
      changeset = User.registration_changeset(%User{}, %{password: "short"})
      refute changeset.valid?
      assert "should be at least 6 character(s)" in errors_on(changeset).password
    end

    test "changeset with missing required fields" do
      changeset = User.changeset(%User{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).email
      assert "can't be blank" in errors_on(changeset).hashed_password
    end

    test "changeset with invalid role" do
      changeset = User.changeset(%User{}, %{role: :invalid_role})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).role
    end

    test "registration_changeset with valid attributes" do
      valid_attrs = %{
        email: "test@example.com",
        password: "testpassword123",
        first_name: "John",
        last_name: "Doe",
        role: :customer
      }

      changeset = User.registration_changeset(%User{}, valid_attrs)
      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
    end

    test "registration_changeset with weak password" do
      changeset = User.registration_changeset(%User{}, %{password: "weak"})
      refute changeset.valid?
      assert "should be at least 6 character(s)" in errors_on(changeset).password
    end
  end
end
