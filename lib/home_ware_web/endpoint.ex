defmodule HomeWareWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :home_ware

  # Use session options from config, falling back to default
  @session_options Application.compile_env(:home_ware, HomeWareWeb.Endpoint)[:session_options] ||
                     [
                       store: :cookie,
                       key: "_home_ware_key",
                       signing_salt: "Og6CcweZ",
                       same_site: "Lax"
                     ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :home_ware,
    gzip: false,
    only: HomeWareWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :home_ware
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug HomeWareWeb.Router

  def fetch_current_user(conn, _opts) do
    HomeWareWeb.UserAuthGuardian.fetch_current_user(conn, [])
  end

  def require_authenticated_user(conn, _opts) do
    HomeWareWeb.UserAuthGuardian.require_authenticated_user(conn, [])
  end
end
