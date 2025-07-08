defmodule HomeWare.Repo do
  use Ecto.Repo,
    otp_app: :home_ware,
    adapter: Ecto.Adapters.Postgres
end
