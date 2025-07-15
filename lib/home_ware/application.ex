defmodule HomeWare.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HomeWareWeb.Telemetry,
      HomeWare.Repo,
      {DNSCluster, query: Application.get_env(:home_ware, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HomeWare.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: HomeWare.Finch},
      # Start a worker by calling: HomeWare.Worker.start_link(arg)
      # {HomeWare.Worker, arg},
      # Start to serve requests, typically the last entry
      HomeWareWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeWare.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Configure bucket for public access (only in dev/prod, not test)
    if Mix.env() != :test do
      HomeWare.UploadService.ensure_bucket_public_access()
    end

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HomeWareWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
