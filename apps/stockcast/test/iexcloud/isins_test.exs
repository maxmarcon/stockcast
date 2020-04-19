defmodule Stockcast.IexCloud.IsinsTest do
  use Stockcast.DataCase

  alias Stockcast.IexCloud.{Isins, Isin}
  alias Stockcast.Repo

  @isin "IE00B4L5Y983"
  @invalid_isin "XIE00B4L5Y983X"
  @old_iex_id "IEX_42423450545A2D52"

  describe "fetch/1" do
    setup do
      api_isins = Jason.decode!(File.read!("#{__DIR__}/api_isins.json"))

      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_isins, status: 200} end)

      [api_isins: api_isins]
    end

    test "fetches and stores new isins" do
      assert {:ok, %{deleted: 0, created: 3}} == Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 3

      Enum.each(
        isins,
        fn %{isin: isin, iex_id: iex_id} ->
          assert isin == @isin
          refute is_nil(iex_id)
        end
      )
    end

    test "doesn't save isins with wrong format" do
      assert {:error, %{errors: [isin: {_, [validation: :format]}]}} = Isins.fetch(@invalid_isin)

      assert Repo.aggregate(Isin, :count) == 0
    end

    test "deletes existing isins" do
      {:ok, _} = Repo.insert(%Isin{isin: @isin, iex_id: "OLD_IEX_ID"})

      assert {:ok, %{deleted: 1, created: 3}} == Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 3

      Enum.each(
        isins,
        fn %{isin: isin, iex_id: iex_id} ->
          assert isin == @isin
          refute is_nil(iex_id)
        end
      )
    end

    test "does not delete existing isins if new ones are invalid" do
      {:ok, _} = Repo.insert(%Isin{isin: @invalid_isin, iex_id: @old_iex_id})

      assert {:error, _} = Isins.fetch(@invalid_isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @invalid_isin, iex_id: @old_iex_id} | _] = isins
    end

    test "adds an isin with null iex_id in case of empty response" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: [], status: 200} end)

      assert {:ok, %{created: 1, deleted: 0}} = Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @isin, iex_id: nil} | _] = isins
    end

    test "adds an isin with null iex_id in case of empty response (2)" do
      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: nil, status: 200} end)

      assert {:ok, %{created: 1, deleted: 0}} = Isins.fetch(@isin)

      isins = Repo.all(Isin)
      assert length(isins) == 1

      assert [%{isin: @isin, iex_id: nil} | _] = isins
    end
  end
end
