use Mix.Config

# Configure your database
config :stockcast,
       Stockcast.Repo,
       username: "postgres",
       password: "postgres",
       database: "stockcast_test",
       hostname: "localhost",
       pool: Ecto.Adapters.SQL.Sandbox,
       log: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stockcast_web,
       StockcastWeb.Endpoint,
       http: [
         port: 4002
       ],
       server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

config :stockcast,
       Stockcast.IexCloud.Api,
       api_token: "fake_token",
       base_url: "https://sandbox.iexapis.com/v1"

config :junit_formatter,
  print_report_file: true,
  prepend_project_name?: true,
  report_dir: "../../test-results/exunit"
