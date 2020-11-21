import Config

config :stockcast, Stockcast.Repo, ssl: false

config :stockcast,
       Stockcast.IexCloud.Api,
       base_url: "https://cloud.iexapis.com/v1"

# Do not print debug messages in production
config :logger, level: :info

config :stockcast_web, StockcastWeb.Endpoint,
  http: [port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true
