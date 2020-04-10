defmodule Stockcast.IexCloud.ServiceTest do
  use Stockcast.DataCase

  import Mock

  alias Stockcast.IexCloud.{Service, Symbol, Api}
  alias Stockcast.Repo

  setup do
    api_symbols = Jason.decode!(File.read!("#{__DIR__}/api_symbols.json"))

    [api_symbols: api_symbols]
  end

  test "can fetch symbols", %{api_symbols: api_symbols} do
    with_mock Api, get: fn _ -> api_symbols end do
      assert {:ok, 2} == Service.fetch_symbols("path")

      assert 2 == Repo.aggregate(Symbol, :count)
    end
  end
end
