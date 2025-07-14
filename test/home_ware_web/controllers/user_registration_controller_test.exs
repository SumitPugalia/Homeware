defmodule HomeWareWeb.UserRegistrationControllerTest do
  use HomeWareWeb.ConnCase

  describe "GET /users/register" do
    test "renders registration form", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert html_response(conn, 200) =~ "Create an account"
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
      assert @flash[:info] =~ "Registration successful"
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
      html = html_response(conn, 200)
      assert html =~ "Create an account"
      assert html =~ "must have the @ sign and no spaces"
      assert html =~ "must include at least one lowercase letter"
      assert html =~ "should be at least %{count} character(s)"
    end

    test "shows error for invalid email format", %{conn: conn} do
      user_params = %{
        "user" => %{
          "email" => "not-an-email",
          "first_name" => "Test",
          "password" => "password123"
        }
      }

      conn = post(conn, ~p"/users/register", user_params)
      html = html_response(conn, 200)
      assert html =~ "must have the @ sign and no spaces"
    end

    test "shows error for short password", %{conn: conn} do
      user_params = %{
        "user" => %{
          "email" => "test@example.com",
          "first_name" => "Test",
          "password" => "123"
        }
      }

      conn = post(conn, ~p"/users/register", user_params)
      html = html_response(conn, 200)
      assert html =~ "must include at least one lowercase letter"
    end

    test "shows error for missing required fields", %{conn: conn} do
      user_params = %{
        "user" => %{
          "email" => "",
          "first_name" => "",
          "password" => ""
        }
      }

      conn = post(conn, ~p"/users/register", user_params)
      html = html_response(conn, 200)
      assert html =~ "can&#39;t be blank"
    end
  end
end
