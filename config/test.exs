import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :home_ware, HomeWare.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  database: "home_ware_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :home_ware, HomeWareWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PINOY6l/DYOt7eTow2QV+CIMnIbfEsoPgK1087+V9AirmKody1ikAN0MRmcKprwN",
  server: false,
  session_options: [
    store: :cookie,
    key: "_home_ware_key",
    signing_salt: "Og6CcweZ",
    same_site: "Lax"
  ]

# In test we don't send emails.
config :home_ware, HomeWare.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Guardian configuration for tests
config :home_ware, HomeWare.Guardian,
  issuer: "home_ware_test",
  secret_key: "+ftxPuEyBowpC/YVD8GcLzDdcjqXLRRXV4bA50xR1rdT1YzmH5zXhP65U9HulmHh"
