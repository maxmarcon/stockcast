defmodule Stockcast.IexCloud.SymbolsTest do
  use Stockcast.DataCase

  alias Stockcast.IexCloud.{Symbols, Symbol}
  alias Stockcast.Repo

  setup do
    api_symbols = Jason.decode!(File.read!("#{__DIR__}/api_symbols.json"))

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_symbols, status: 200} end)

    [api_symbols: api_symbols]
  end

  describe "fetch/1" do
    test "fetches and saves symbols", %{api_symbols: api_symbols} do
      assert {:ok, %{fetched: 2, saved: 2}} == Symbols.fetch("path")

      assert 2 == Repo.aggregate(Symbol, :count)

      assert Repo.all(from Symbol, order_by: [:iex_id])
             |> Enum.map(& &1.iex_id) ==
               Enum.map(api_symbols, &Access.get(&1, "iexId"))
               |> Enum.sort()
    end

    test "doesn't save symbols if some data is missing", %{api_symbols: api_symbols} do
      api_symbols = [
        List.first(api_symbols),
        List.last(api_symbols)
        |> Map.delete("name")
      ]

      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_symbols, status: 200} end)

      assert {:ok, %{fetched: 2, saved: 1}} == Symbols.fetch("path")

      assert 1 == Repo.aggregate(Symbol, :count)

      assert Repo.one(Symbol).iex_id == "IEX_46574843354B2D52"
    end

    test "updates symbols if given iex_id already exists", %{api_symbols: api_symbols} do
      api_symbol_1 = List.first(api_symbols)

      api_symbol_2 =
        Enum.at(api_symbols, 1)
        |> Map.put("iexId", api_symbol_1["iexId"])

      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: [api_symbol_1], status: 200} end)

      assert {:ok, %{fetched: 1, saved: 1}} == Symbols.fetch("path")

      assert 1 == Repo.aggregate(Symbol, :count)
      initial_symbol = Repo.one(Symbol)

      assert initial_symbol.iex_id == api_symbol_1["iexId"]
      assert initial_symbol.symbol == "A"

      Process.sleep(1000)

      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: [api_symbol_2], status: 200} end)

      assert {:ok, %{fetched: 1, saved: 1}} == Symbols.fetch("path")

      assert 1 == Repo.aggregate(Symbol, :count)
      updated_symbol = Repo.one(Symbol)

      assert updated_symbol.iex_id == initial_symbol.iex_id
      assert updated_symbol.symbol == "AA"
      assert updated_symbol.inserted_at == initial_symbol.inserted_at
      refute updated_symbol.updated_at == initial_symbol.updated_at
    end

    test "passes through api errors" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: "API_ERROR", status: 422} end)

      assert {:error, "API_ERROR"} == Symbols.fetch("path")
    end
  end
end
