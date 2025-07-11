defmodule HomeWareWeb.UserRegistrationControllerTest do
  use HomeWareWeb.ConnCase

  test "GET /users/register returns 200", %{conn: conn} do
    conn = get(conn, ~p"/users/register")
    assert html_response(conn, 200)
  end

  test "POST /users/register with valid data redirects", %{conn: conn} do
    valid_attrs = %{
      "user" => %{
        "email" => "test@example.com",
        "password" => "testpassword123",
        "first_name" => "John",
        "last_name" => "Doe"
      }
    }

    conn = post(conn, ~p"/users/register", valid_attrs)
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  test "POST /users/register with invalid data returns error", %{conn: conn} do
    invalid_attrs = %{
      "user" => %{
        "email" => "invalid-email",
        "password" => "short"
      }
    }

    conn = post(conn, ~p"/users/register", invalid_attrs)
    assert html_response(conn, 200) =~ "error"
  end
end
