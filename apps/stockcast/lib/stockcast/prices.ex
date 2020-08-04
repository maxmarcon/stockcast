defmodule Stockcast.Prices do
  alias Stockcast.IexCloud.HistoricalPrices, as: IexPrices

  @doc ~S"""
  retrieve stock prices for a particular symbol
  """
  @spec retrieve(binary(), Date.t(), %Date{}) ::
          {:ok, [%{}]} | {:error, atom()}
  def retrieve(symbol, from, to \\ Date.add(Date.utc_today(), -1), sampling \\ 1)
      when is_binary(symbol) and is_integer(sampling) and sampling >= 1,
      do: IexPrices.retrieve(symbol, from, to, sampling)
end
