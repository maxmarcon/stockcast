defmodule Stockcast.Performance do
  alias __MODULE__

  @decimal_zero Decimal.new(0)
  @type t :: %Performance{}

  @derive Jason.Encoder
  defstruct baseline: nil,
            relative: false,
            raw: @decimal_zero,
            trading: @decimal_zero,
            short_trading: @decimal_zero,
            strategy: []

  @spec relative(Performance.t()) :: Performance.t()
  @doc ~S'''
  iex> Stockcast.Performance.relative(%Stockcast.Performance{relative: false, baseline: Decimal.cast(5), raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{relative: true, baseline: Decimal.cast(5), raw: Decimal.cast(2), trading: Decimal.cast(1), short_trading: Decimal.cast(3)}

  iex> Stockcast.Performance.relative(%Stockcast.Performance{relative: true, baseline: Decimal.cast(5), raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{relative: true, baseline: Decimal.cast(5), raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)}

  iex> Stockcast.Performance.relative(%Stockcast.Performance{relative: false, baseline: nil, raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{relative: false, baseline: nil, raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)}

  iex> Stockcast.Performance.relative(%Stockcast.Performance{relative: false, baseline: Decimal.cast(0), raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)})
  %Stockcast.Performance{relative: false, baseline: Decimal.cast(0), raw: Decimal.cast(10), trading: Decimal.cast(5), short_trading: Decimal.cast(15)}
  '''
  def relative(%Performance{baseline: nil} = performance), do: performance

  def relative(%Performance{baseline: @decimal_zero} = performance), do: performance

  def relative(
        performance = %Performance{
          baseline: baseline,
          relative: false,
          raw: raw,
          trading: trading,
          short_trading: short_trading
        }
      ) do
    %{
      performance
      | relative: true,
        raw: Decimal.div(raw, baseline),
        trading: Decimal.div(trading, baseline),
        short_trading: Decimal.div(short_trading, baseline)
    }
  end

  def relative(%Performance{relative: true} = performance), do: performance
end
