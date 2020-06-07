import Config

config :stockcast, Stockcast.Repo,
  url: System.get_env("DATABASE_URL"),
  ssl: false,
  pool_size: 2

config :stockcast,
       Stockcast.IexCloud.Api,
       base_url: "https://cloud.iexapis.com/v1",
       api_token: System.get_env("IEXCLOUD_API_TOKEN")

# Do not print debug messages in production
config :logger, level: :info

config :stockcast_web, StockcastWeb.Endpoint,
  http: [port: 4000],
  url: [
    host: System.get_env("HOST_NAME"),
    scheme: System.get_env("SCHEME", "https"),
    port: System.get_env("PORT", "443")
  ],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE}"),
  server: true
