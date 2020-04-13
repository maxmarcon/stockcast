# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :stockcast,
  ecto_repos: [Stockcast.Repo]

config :stockcast_web,
  ecto_repos: [Stockcast.Repo],
  generators: [
    context_app: :stockcast
  ]

config :stockcast,
       Stockcast.IexCloud.Symbols,
       symbol_paths: [
         "ref-data/mutual-funds/symbols",
         "ref-data/region/DE/symbols",
         "ref-data/region/FR/symbols",
         "ref-data/region/GB/symbols",
         "ref-data/region/NL/symbols",
         "ref-data/region/IE/symbols",
         "ref-data/region/BE/symbols",
         "ref-data/otc/symbols",
         "ref-data/symbols"
       ]

# Configures the endpoint
config :stockcast_web,
       StockcastWeb.Endpoint,
       url: [
         host: "localhost"
       ],
       secret_key_base: "O52M2DtWGwEUukDyzq9xLdL7gzte5bDJfPhrYg98XUzJ6jL9ZT3YV9NAihwzLu9Q",
       render_errors: [
         view: StockcastWeb.ErrorView,
         accepts: ~w(json)
       ],
       pubsub: [
         name: StockcastWeb.PubSub,
         adapter: Phoenix.PubSub.PG2
       ],
       live_view: [
         signing_salt: "iJL1mGvO"
       ]

# Configures Elixir's Logger
config :logger,
       :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
