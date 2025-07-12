defmodule HomeWareWeb.PageControllerTest do
  use HomeWareWeb.ConnCase

  test "GET / returns 200", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert conn.status == 200
  end

  test "GET / returns HTML", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200)
  end

  test "GET / contains expected content", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Exclusive"
    assert html =~ "Flash Sales"
    assert html =~ "Browse By Category"
    assert html =~ "Best Selling Products"
    assert html =~ "FREE AND FAST DELIVERY"
  end
end
