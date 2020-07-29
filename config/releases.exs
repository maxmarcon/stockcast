import Config

config :stockcast, Stockcast.Repo, url: System.get_env("DATABASE_URL")

config :stockcast,
       Stockcast.IexCloud.Api,
       api_token: System.get_env("IEXCLOUD_API_TOKEN")

config :stockcast_web, StockcastWeb.Endpoint,
  url: [
    host: System.get_env("HOST_NAME"),
    scheme: System.get_env("SCHEME", "https"),
    port: System.get_env("PORT", "443")
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE}")
