defmodule HomeWare.SimpleDbTest do
  use HomeWare.DataCase

  test "database connection works" do
    # Test that we can connect to the database
    assert HomeWare.Repo.config()[:database] =~ "home_ware_test"
  end

  test "can create and find a simple record" do
    # Test basic database operations
    user = %HomeWare.Accounts.User{
      id: Ecto.UUID.generate(),
      email: "test@example.com",
      hashed_password: "hashed_password",
      first_name: "Test",
      last_name: "User",
      role: :customer,
      is_active: true
    }

    {:ok, saved_user} = HomeWare.Repo.insert(user)
    found_user = HomeWare.Repo.get(HomeWare.Accounts.User, saved_user.id)

    assert found_user.email == "test@example.com"
  end
end
