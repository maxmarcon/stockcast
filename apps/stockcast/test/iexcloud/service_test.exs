defmodule Stockcast.IexCloud.ServiceTest do
  use Stockcast.DataCase

  import Mock

  alias Stockcast.IexCloud.{Service, Symbol, Api}
  alias Stockcast.Repo

  setup do
    api_symbols = Jason.decode!(File.read!("#{__DIR__}/api_symbols.json"))

    [api_symbols: api_symbols]
  end

  describe "fetch_symbols/1" do
    test "fetches and saves symbols", %{api_symbols: api_symbols} do
      with_mock Api, get: fn _ -> api_symbols end do
        assert {:ok, 2} == Service.fetch_symbols("path")

        assert 2 == Repo.aggregate(Symbol, :count)

        assert Repo.all(from Symbol, order_by: [:iex_id]) |> Enum.map(& &1.iex_id) ==
                 Enum.map(api_symbols, &Access.get(&1, "iexId")) |> Enum.sort()
      end
    end

    test "doesn't save symbols if some data is missing", %{api_symbols: api_symbols} do
      api_symbols = [
        List.first(api_symbols),
        List.last(api_symbols)
        |> Map.delete("name")
      ]

      with_mock Api, get: fn _ -> api_symbols end do
        assert {:ok, 1} == Service.fetch_symbols("path")

        assert 1 == Repo.aggregate(Symbol, :count)

        assert Repo.one(Symbol).iex_id == "IEX_46574843354B2D52"
      end
    end

    test "updates entries if iex_id alrady exists", %{api_symbols: api_symbols} do
      api_symbols = [
        List.first(api_symbols),
        List.last(api_symbols)
        |> Map.put("iexId", Access.get(List.first(api_symbols), "iexId"))
      ]

      with_mock Api, get: fn _ -> api_symbols end do
        assert {:ok, 2} == Service.fetch_symbols("path")

        assert 1 == Repo.aggregate(Symbol, :count)
        symbol = Repo.one(Symbol)

        assert symbol.iex_id == "IEX_46574843354B2D52"
        assert symbol.symbol == "AA"
      end
    end
  end
end
