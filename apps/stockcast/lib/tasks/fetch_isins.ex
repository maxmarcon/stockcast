defmodule Mix.Tasks.Fetch.Isins do
  @iexcloud "IexCloud"

  @moduledoc ~s"""
  fetches isin from #{@iexcloud}

    * `isin_1 isin_2 ...` - isins to fetch
  """
  @shortdoc "fetches #{@iexcloud} isins"

  use Mix.Task

  import Mix.Tasks.Utils

  alias Stockcast.IexCloud.Isins

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    {_, isins, _} = OptionParser.parse(args, strict: [])

    if length(isins) == 0 do
      fail("you need to specify at least an ISIN to fetch")
    end

    start_time = Time.utc_now()

    %{deleted: deleted, created: created} =
      Enum.reduce(isins, %{deleted: 0, created: 0}, &fetch_isin/2)

    ok(
      "deleted #{deleted} old ISINs, created #{created} new ones in #{
        format_msec(Time.diff(Time.utc_now(), start_time, :millisecond))
      }"
    )
  end

  defp fetch_isin(isin, %{deleted: deleted, created: created}) do
    progress("fetching ISIN #{isin}")

    case Isins.fetch(isin) do
      {:ok, %{deleted: d, created: c}} ->
        %{deleted: deleted + d, created: created + c}

      {:error, err} ->
        error("error saving isin #{isin}", err)
        %{deleted: deleted, created: created}
    end
  end
end
