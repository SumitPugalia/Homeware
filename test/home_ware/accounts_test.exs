defmodule HomeWare.AccountsTest do
  use HomeWare.DataCase

  alias HomeWare.Accounts
  alias HomeWare.Accounts.User
  alias HomeWare.Factory

  describe "users" do
    test "register_user/1 with valid data creates a user" do
      valid_attrs = %{
        email: "test@example.com",
        password: "testpassword123",
        first_name: "John",
        last_name: "Doe",
        role: :customer
      }

      assert {:ok, %User{} = user} = Accounts.register_user(valid_attrs)
      assert user.email == "test@example.com"
      assert user.first_name == "John"
      assert user.last_name == "Doe"
      assert user.role == :customer
    end

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(%{email: nil})
    end

    test "get_user!/1 returns the user with given id" do
      user = Factory.insert(:user)
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user_by_email/1 returns the user with given email" do
      user = Factory.insert(:user, %{email: "test@example.com"})
      assert Accounts.get_user_by_email("test@example.com") == user
    end

    test "update_user/2 with valid data updates the user" do
      user = Factory.insert(:user)
      update_attrs = %{first_name: "Jane", last_name: "Smith"}

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, update_attrs)
      assert updated_user.first_name == "Jane"
      assert updated_user.last_name == "Smith"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = Factory.insert(:user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, %{email: nil})
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = Factory.insert(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = Factory.insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "authenticate_user/2 with valid credentials returns user" do
      user = Factory.insert(:user, %{email: "test@example.com"})
      # Set password for authentication
      {:ok, _user_with_password} =
        Accounts.update_user(user, %{hashed_password: Bcrypt.hash_pwd_salt("testpassword123")})

      assert {:ok, authenticated_user} =
               Accounts.authenticate_user("test@example.com", "testpassword123")

      assert authenticated_user.id == user.id
    end

    test "authenticate_user/2 with invalid credentials returns error" do
      Factory.insert(:user, %{email: "test@example.com"})

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("test@example.com", "wrongpassword")
    end

    test "deliver_user_confirmation_instructions/2 returns ok" do
      user = Factory.insert(:user)
      assert :ok = Accounts.deliver_user_confirmation_instructions(user, fn _token -> :ok end)
    end
  end
end
