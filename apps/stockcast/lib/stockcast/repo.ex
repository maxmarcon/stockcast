defmodule Stockcast.Repo do
  use Ecto.Repo,
    otp_app: :stockcast,
    adapter: Ecto.Adapters.Postgres
end
