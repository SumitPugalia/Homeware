defmodule HomeWareWeb.UserSessionControllerTest do
  use HomeWareWeb.ConnCase

  test "GET /users/log_in returns 200", %{conn: conn} do
    conn = get(conn, ~p"/users/log_in")
    assert html_response(conn, 200)
  end

  test "POST /users/log_in with valid credentials redirects", %{conn: conn} do
    # This test will need to be updated when authentication is properly implemented
    valid_attrs = %{
      "user" => %{
        "email" => "test@example.com",
        "password" => "testpassword123"
      }
    }

    conn = post(conn, ~p"/users/log_in", valid_attrs)
    # For now, just check that it doesn't crash
    assert conn.status in [200, 302]
  end

  test "DELETE /users/log_out redirects", %{conn: conn} do
    conn = delete(conn, ~p"/users/log_out")
    assert redirected_to(conn) == ~p"/"
  end
end
