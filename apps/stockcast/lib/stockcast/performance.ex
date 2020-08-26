defmodule Stockcast.Performance do
  alias __MODULE__
  alias Stockcast.IexCloud.HistoricalPrice

  @decimal_zero Decimal.new(0)
  @type t :: %Performance{}

  defstruct raw: @decimal_zero,
            trading: @decimal_zero,
            short_trading: @decimal_zero,
            strategy: []

  @spec relative(Performance.t()) :: Performance.t()
  @doc ~S'''
  iex> Stockcast.Performance.relative(%Stockcast.Performance{raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{raw: Decimal.cast(10), trading: Decimal.cast(0.5), short_trading: Decimal.cast(1.5)}

  iex> Stockcast.Performance.relative(%Stockcast.Performance{raw: Decimal.cast(0), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{raw: Decimal.cast(0), trading: Decimal.cast(0), short_trading: Decimal.cast(0)}
  '''
  def relative(
        performance = %Performance{raw: raw, trading: trading, short_trading: short_trading}
      )
      when raw == @decimal_zero do
    %{performance | trading: @decimal_zero, short_trading: @decimal_zero}
  end

  def relative(
        performance = %Performance{raw: raw_perf, trading: trading, short_trading: short_trading}
      ) do
    %{
      performance
      | trading: Decimal.div(trading, raw_perf),
        short_trading: Decimal.div(short_trading, raw_perf)
    }
  end

  @spec from_historical_prices([HistoricalPrice.t()]) :: Performance.t()
  def from_historical_prices(prices) do
  end
end
