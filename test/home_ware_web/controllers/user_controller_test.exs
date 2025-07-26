defmodule HomeWareWeb.UserControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup %{conn: conn} do
    %{conn: conn}
  end

  describe "profile" do
    test "GET /profile redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /profile shows profile when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/profile")

      assert html_response(conn, 200) =~ "Profile"
    end
  end

  describe "edit profile" do
    test "GET /profile/edit redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/profile/edit")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /profile/edit shows edit form when authenticated", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/profile/edit")

      assert html_response(conn, 200) =~ "Edit Profile"
    end
  end

  describe "update profile" do
    test "PUT /profile with valid data", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      update_params = %{
        "user" => %{
          "first_name" => "Updated",
          "last_name" => "Name",
          "email" => "updated@example.com",
          "phone" => "1234567890"
        }
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/profile", update_params)

      assert redirected_to(conn) == ~p"/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Profile updated successfully"
    end

    test "PUT /profile with invalid data", %{conn: conn} do
      user = Factory.insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      update_params = %{
        "user" => %{
          "first_name" => "",
          "last_name" => "",
          "email" => "invalid-email",
          "phone" => "1234567890"
        }
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/profile", update_params)

      assert html_response(conn, 200) =~ "Edit Profile"
    end

    test "PUT /profile redirects to login when not authenticated", %{conn: conn} do
      update_params = %{"user" => %{"first_name" => "Updated"}}
      conn = put(conn, ~p"/profile", update_params)
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end
end
