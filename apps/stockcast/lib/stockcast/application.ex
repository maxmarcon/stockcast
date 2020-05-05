defmodule Stockcast.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Stockcast.Repo,
      %{
        id: :iex_cloud_cache,
        start: {Cachex, :start_link, [:iex_cloud, []]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Stockcast.Supervisor)
  end
end
