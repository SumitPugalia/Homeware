defmodule HomeWare.Repo do
  use Ecto.Repo,
    otp_app: :home_ware,
    adapter: Ecto.Adapters.Postgres

  use Scrivener,
    page_size: 10,
    max_page_size: 100
end
