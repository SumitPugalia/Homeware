defmodule HomeWareWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a LiveView connection.

  Such tests rely on `Phoenix.LiveViewTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint HomeWareWeb.Endpoint

      use HomeWareWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import HomeWareWeb.ConnCase
    end
  end

  setup tags do
    HomeWare.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def log_in_admin_user(conn) do
    admin =
      HomeWare.Factory.insert(:user, %{
        role: :admin,
        email: "admin#{System.unique_integer()}@example.com"
      })

    {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(admin)

    conn
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.assign(:current_user, admin)
    |> Plug.Conn.put_session(:user_token, token)
    |> Map.put(:admin, admin)
  end
end
