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

    test "updates symbols if given iex_id already exists", %{api_symbols: api_symbols} do
      api_symbol_1 = List.first(api_symbols)

      api_symbol_2 =
        Enum.at(api_symbols, 1)
        |> Map.put("iexId", api_symbol_1["iexId"])

      initial_symbol =
        with_mock Api, get: fn _ -> [api_symbol_1] end do
          assert {:ok, 1} == Service.fetch_symbols("path")

          assert 1 == Repo.aggregate(Symbol, :count)
          symbol = Repo.one(Symbol)

          symbol
        end

      assert initial_symbol.iex_id == api_symbol_1["iexId"]
      assert initial_symbol.symbol == "A"

      Process.sleep(1000)

      updated_symbol =
        with_mock Api, get: fn _ -> [api_symbol_2] end do
          assert {:ok, 1} == Service.fetch_symbols("path")

          assert 1 == Repo.aggregate(Symbol, :count)
          symbol = Repo.one(Symbol)

          symbol
        end

      assert updated_symbol.iex_id == initial_symbol.iex_id
      assert updated_symbol.symbol == "AA"
      assert updated_symbol.inserted_at == initial_symbol.inserted_at
      refute updated_symbol.updated_at == initial_symbol.updated_at
    end
  end
end
