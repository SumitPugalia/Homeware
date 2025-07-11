defmodule HomeWareWeb.AdminDashboardLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory

  setup do
    user = Factory.insert(:user, %{role: :admin})
    %{user: user}
  end

  describe "index" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/admin/dashboard")
    end

    test "redirects when user is not admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :customer})
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/dashboard")
    end

    test "renders admin dashboard when authenticated as admin", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/admin/dashboard")
      assert html =~ "Admin Dashboard"
    end

    test "shows dashboard stats", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/admin/dashboard")
      assert html =~ "Total Products"
      assert html =~ "Total Users"
      assert html =~ "Total Orders"
    end

    test "refreshes stats", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/admin/dashboard")

      assert index_live
             |> element("button", "Refresh Stats")
             |> render_click()
    end
  end

  defp log_in_user(conn, user) do
    conn
    |> post(~p"/users/log_in", %{
      "user" => %{"email" => user.email, "password" => "password123"}
    })
  end
end
