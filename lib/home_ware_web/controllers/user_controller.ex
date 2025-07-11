defmodule HomeWareWeb.UserController do
  use HomeWareWeb, :controller

  def profile(conn, _params) do
    render(conn, :profile)
  end
end
