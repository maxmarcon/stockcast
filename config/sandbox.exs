import Mix.Config

import_config "dev.exs"

config :stockcast,
       Stockcast.Repo,
       database: "stockcast_sandbox"

config :stockcast,
       Stockcast.IexCloud.Api,
       base_url: "https://sandbox.iexapis.com/v1"

import_config "sandbox.secret.exs"
