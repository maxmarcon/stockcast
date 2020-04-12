defmodule Mix.Tasks.Fetch.Symbols do
  @shortdoc "fetches all configured Iex symbol lists"

  use Mix.Task

  require Logger

  alias Stockcast.IexCloud.Service, as: IexService

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:stockcast)

    Logger.info("fetching all configured symbols...")
    Logger.info("saved #{IexService.fetch_symbols()} symbols")
  end
end
