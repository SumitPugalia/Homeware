defmodule HomeWare.AccountsTest do
  use HomeWare.DataCase

  alias HomeWare.Accounts
  alias HomeWare.Accounts.User
  alias HomeWare.Factory

  describe "accounts" do
    alias HomeWare.Accounts

    test "list_users/0 returns all users" do
      user = Factory.insert(:user)
      assert Accounts.list_users() == [user]
    end

    test "count_customers/0 returns count of active customers" do
      # Create some customers
      Factory.insert(:user, %{role: :customer, is_active: true})
      Factory.insert(:user, %{role: :customer, is_active: true})
      # inactive customer
      Factory.insert(:user, %{role: :customer, is_active: false})
      # admin user
      Factory.insert(:user, %{role: :admin, is_active: true})

      assert Accounts.count_customers() == 2
    end

    test "get_user!/1 returns the user with given id" do
      user = Factory.insert(:user)
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user_by_email/1 returns the user with given email" do
      user = Factory.insert(:user)
      assert Accounts.get_user_by_email(user.email) == user
    end

    test "get_user_by_email_and_password/2 returns the user if email and password are valid" do
      user = Factory.insert(:user, %{hashed_password: Bcrypt.hash_pwd_salt("test123")})
      assert Accounts.get_user_by_email_and_password(user.email, "test123") == user
    end

    test "get_user_by_email_and_password/2 returns nil if email is invalid" do
      assert Accounts.get_user_by_email_and_password("unknown@example.com", "test123") == nil
    end

    test "get_user_by_email_and_password/2 returns nil if password is invalid" do
      user = Factory.insert(:user, %{hashed_password: Bcrypt.hash_pwd_salt("test123")})
      assert Accounts.get_user_by_email_and_password(user.email, "wrong") == nil
    end

    test "authenticate_user/2 returns {:ok, user} if email and password are valid" do
      user = Factory.insert(:user, %{hashed_password: Bcrypt.hash_pwd_salt("test123")})
      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, "test123")
      assert authenticated_user == user
    end

    test "authenticate_user/2 returns {:error, :invalid_credentials} if email is invalid" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("unknown@example.com", "test123")
    end

    test "authenticate_user/2 returns {:error, :invalid_credentials} if password is invalid" do
      user = Factory.insert(:user, %{hashed_password: Bcrypt.hash_pwd_salt("test123")})
      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, "wrong")
    end

    test "update_user/2 with valid data updates the user" do
      user = Factory.insert(:user)
      update_attrs = %{first_name: "Updated Name"}

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, update_attrs)
      assert updated_user.first_name == "Updated Name"
    end

    test "change_user/1 returns a user changeset" do
      user = Factory.insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "change_user_registration/1 returns a user changeset" do
      user = Factory.insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user_registration(user)
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{
        email: "test@example.com",
        hashed_password: "test123",
        first_name: "Test",
        last_name: "User",
        role: :customer
      }

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "test@example.com"
      assert user.first_name == "Test"
      assert user.last_name == "User"
      assert user.role == :customer
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{email: nil})
    end

    test "delete_user/1 deletes the user" do
      user = Factory.insert(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end
  end
end
