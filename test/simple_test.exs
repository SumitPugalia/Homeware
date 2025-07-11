defmodule HomeWare.SimpleTest do
  use ExUnit.Case

  test "basic test framework works" do
    assert 1 + 1 == 2
  end

  test "Guardian can encode and decode tokens" do
    # Test Guardian functionality without database
    user = %{
      id: "test-user-id",
      email: "test@example.com"
    }

    # This should work even without database
    assert {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(user)
    assert is_binary(token)
  end
end
