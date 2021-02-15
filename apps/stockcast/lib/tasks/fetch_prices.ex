defmodule Mix.Tasks.Fetch.Prices do
  @iexcloud "IexCloud"

  @moduledoc ~s"""
  fetches historical prices from #{@iexcloud} and outputs them in CSV format to stdout

    * `<SYMBOL>` - symbol 
    * `--from <DATE>` - from date 
    * `--to <DATE>` - to date, defaults to yesterday if omitted
    * `--stdout` - if set, write to standard output
  """
  @shortdoc "fetches #{@iexcloud} historical prices"

  use Mix.Task

  import Mix.Tasks.Utils

  alias Stockcast.IexCloud.HistoricalPrices

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    {options, symbols, _} =
      OptionParser.parse(args, strict: [from: :string, to: :string, stdout: :boolean])

    if !options[:from] do
      fail("Need to specify the --from <date> option")
    end

    from = Date.from_iso8601!(options[:from])

    to =
      if options[:to] do
        Date.from_iso8601!(options[:to])
      else
        Date.add(Date.utc_today(), -1)
      end

    if length(symbols) != 1 do
      fail("You need to specify exactly one symbol")
    end

    [symbol] = symbols

    case HistoricalPrices.retrieve(symbol, from, to) do
      {:error, error} ->
        fail(to_string(error))

      {:error, :too_old, earliest_fetchable} ->
        fail("Earliest fetchable date is: #{earliest_fetchable}")

      {:ok, prices} ->
        write_prices(prices, symbol, from, to, options[:stdout])
    end
  end

  defp write_prices(prices, symbol, from, to, stdout) do
    file =
      if stdout do
        :stdio
      else
        filename = "prices-#{symbol}-#{from}-#{to}.csv"
        ok("writing prices to: #{filename}")
        File.open!(filename, [:write])
      end

    prices
    |> Enum.map(&Map.put(&1, :day_of_week, Date.day_of_week(&1.date)))
    |> CSV.encode(
      delimiter: "\n",
      headers: [
        :day_of_week,
        :symbol,
        :date,
        :open,
        :high,
        :low,
        :close,
        :volume,
        :change,
        :changePercent
      ]
    )
    |> Enum.each(&IO.write(file, &1))
  end
end
