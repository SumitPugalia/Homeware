defmodule HomeWareWeb.UserRegistrationControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Accounts

  describe "GET /users/register" do
    test "renders registration form", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert html_response(conn, 200) =~ "Create your account"
    end
  end

  describe "POST /users/register" do
    test "creates user with valid data", %{conn: conn} do
      user_params = %{
        "user" => %{
          "email" => "test@example.com",
          "first_name" => "Test",
          "last_name" => "User",
          "password" => "password123",
          "phone" => "1234567890"
        }
      }

      conn = post(conn, ~p"/users/register", user_params)
      assert redirected_to(conn) == ~p"/users/log_in"
      assert get_flash(conn, :info) =~ "Registration successful"
    end

    test "returns error with invalid data", %{conn: conn} do
      user_params = %{
        "user" => %{
          "email" => "invalid-email",
          "first_name" => "",
          "last_name" => "",
          "password" => "123",
          "phone" => ""
        }
      }

      conn = post(conn, ~p"/users/register", user_params)
      assert html_response(conn, 200) =~ "Create your account"
    end
  end
end
