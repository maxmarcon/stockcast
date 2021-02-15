defmodule Stockcast.IexCloud.IsinsTest do
  use Stockcast.DataCase

  import Stockcast.TestUtils

  alias Stockcast.IexCloud.{Isins, Isin}
  alias Stockcast.Repo

  @isin "IE00B4L5Y983"
  @invalid_isin "XIE00B4L5Y983X"
  @old_symbol "SWDA-LN"

  setup do
    mock_isin_api()
    :ok
  end

  describe "fetch/1" do
    test "fetches and stores new isins" do
      assert {:ok, %{deleted: 0, created: 3}} == Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 3

      check_isins(isins)
    end

    test "doesn't save isins with wrong format" do
      assert {:error, %{errors: [isin: {_, [validation: :format]}]}} = Isins.fetch(@invalid_isin)

      assert Repo.aggregate(Isin, :count) == 0
    end

    test "deletes existing isins" do
      {:ok, _} = Repo.insert(%Isin{isin: @isin, symbol: "OLD_SYMBOL"})

      assert {:ok, %{deleted: 1, created: 3}} == Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 3

      check_isins(isins)
    end

    test "does not delete existing isins if new ones are invalid" do
      {:ok, _} = Repo.insert(%Isin{isin: @invalid_isin, symbol: @old_symbol})

      assert {:error, _} = Isins.fetch(@invalid_isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @invalid_isin, symbol: @old_symbol} | _] = isins
    end

    test "adds an isin with null symbol in case of empty response" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: [], status: 200} end)

      assert {:ok, %{created: 1, deleted: 0}} = Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @isin, symbol: nil} | _] = isins
    end

    test "adds an isin with null symbol in case of empty response (2)" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: nil, status: 200} end)

      assert {:ok, %{created: 1, deleted: 0}} = Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @isin, symbol: nil} | _] = isins
    end

    test "doesn't add an isin with null symbol if format is wrong" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: [], status: 200} end)

      assert {:error, %{errors: [isin: {_, [validation: :format]}]}} = Isins.fetch(@invalid_isin)

      assert Repo.aggregate(Isin, :count) == 0
    end
  end

  describe "fetch!/1" do
    test "fetches and stores new isins" do
      assert %{deleted: 0, created: 3} == Isins.fetch!(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 3

      check_isins(isins)
    end

    test "raises in case of error" do
      assert_raise RuntimeError, ~r/Error while retrieving isins/, fn ->
        Isins.fetch!(@invalid_isin)
      end

      assert Repo.aggregate(Isin, :count) == 0
    end
  end

  defp check_isins(isins) do
    Enum.each(
      isins,
      fn %{isin: isin, symbol: symbol} ->
        assert isin == @isin
        refute is_nil(symbol)
      end
    )
  end
end
