defmodule HomeWare.GuardianTest do
  use HomeWare.DataCase

  alias HomeWare.Guardian
  alias HomeWare.Factory

  setup do
    user = Factory.insert(:user)
    %{user: user}
  end

  describe "token generation and verification" do
    test "can encode and sign a user", %{user: user} do
      assert {:ok, token, _claims} = Guardian.encode_and_sign(user)
      assert is_binary(token)
    end

    test "can decode and verify a token", %{user: user} do
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      assert {:ok, decoded_user, _claims} = Guardian.resource_from_token(token)
      assert decoded_user.id == user.id
    end

    test "returns error for invalid token" do
      assert {:error, _reason} = Guardian.resource_from_token("invalid_token")
    end

    test "can revoke a token", %{user: user} do
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      assert {:ok, _claims} = Guardian.revoke(token)
    end
  end
end
