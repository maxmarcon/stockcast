use Mix.Config

# Configure your database
config :stockcast,
       Stockcast.Repo,
       username: "postgres",
       password: "postgres",
       database: "stockcast_dev",
       hostname: "localhost",
       show_sensitive_data_on_connection_error: true,
       pool_size: 10,
       log: false

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :stockcast_web,
       StockcastWeb.Endpoint,
       http: [
         port: 4000
       ],
       debug_errors: false,
       code_reloader: true,
       check_origin: false,
       watchers: []

config :stockcast,
       Stockcast.IexCloud.Api,
       base_url: "https://sandbox.iexapis.com/v1"

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :tesla, Tesla.Middleware.Logger, debug: false

import_config "dev.secret.exs"
