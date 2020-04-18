defmodule Stockcast.IexCloud.IsinsTest do
  use Stockcast.DataCase

  alias Stockcast.IexCloud.{Isins, Isin}
  alias Stockcast.Repo

  @isin "IE00B4L5Y983"

  describe "fetch/1" do
    setup do
      api_isins = Jason.decode!(File.read!("#{__DIR__}/api_isins.json"))

      Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{body: api_isins, status: 200} end)

      [api_isins: api_isins]
    end

    test "fetches and stores new isins" do
      assert {:ok, %{deleted: 0, created: 3}} == Isins.fetch(@isin)
    end
  end
end
