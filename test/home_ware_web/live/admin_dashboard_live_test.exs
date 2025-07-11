defmodule HomeWareWeb.AdminDashboardLiveTest do
  use HomeWareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HomeWare.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(HomeWare.Repo, {:shared, self()})
    user = Factory.insert(:user, %{role: :admin})
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    %{user: user, token: token}
  end

  defp log_in_user(conn, user, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> assign(:current_user, user)
  end

  describe "index" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/admin/dashboard")
    end

    test "redirects when user is not admin", %{conn: conn} do
      user = Factory.insert(:user, %{role: :customer})
      {:ok, token, _claims} = Guardian.encode_and_sign(user)
      conn = log_in_user(conn, user, token)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/dashboard")
    end

    test "renders admin dashboard when authenticated as admin", %{
      conn: conn,
      user: user,
      token: token
    } do
      conn = log_in_user(conn, user, token)
      {:ok, _index_live, html} = live(conn, ~p"/admin/dashboard")
      assert html =~ "Admin Dashboard"
    end

    test "shows dashboard stats", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, _index_live, html} = live(conn, ~p"/admin/dashboard")
      assert html =~ "Total Products"
      assert html =~ "Total Users"
      assert html =~ "Total Orders"
    end

    test "refreshes stats", %{conn: conn, user: user, token: token} do
      conn = log_in_user(conn, user, token)
      {:ok, index_live, _html} = live(conn, ~p"/admin/dashboard")

      assert index_live
             |> element("button", "Refresh Stats")
             |> render_click()
    end
  end
end
