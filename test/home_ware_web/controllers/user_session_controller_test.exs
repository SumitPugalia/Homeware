defmodule HomeWareWeb.UserSessionControllerTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory

  setup do
    user =
      Factory.insert(:user, %{
        email: "test@example.com",
        hashed_password: Bcrypt.hash_pwd_salt("testpassword123")
      })

    %{user: user}
  end

  test "GET /users/log_in returns 200", %{conn: conn} do
    conn = get(conn, ~p"/users/log_in")
    assert html_response(conn, 200)
  end

  test "POST /users/log_in with valid credentials redirects", %{conn: conn, user: user} do
    valid_attrs = %{
      "user" => %{
        "email" => user.email,
        "password" => "testpassword123"
      }
    }

    conn = post(conn, ~p"/users/log_in", valid_attrs)
    assert redirected_to(conn) == ~p"/"
  end

  test "POST /users/log_in with invalid credentials shows error", %{conn: conn} do
    invalid_attrs = %{
      "user" => %{
        "email" => "wrong@example.com",
        "password" => "wrongpassword"
      }
    }

    conn = post(conn, ~p"/users/log_in", invalid_attrs)
    assert html_response(conn, 200) =~ "Invalid email or password"
  end

  test "DELETE /users/log_out redirects", %{conn: conn} do
    conn = delete(conn, ~p"/users/log_out")
    assert redirected_to(conn) == ~p"/"
  end
end
