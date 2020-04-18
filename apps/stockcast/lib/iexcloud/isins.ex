defmodule Stockcast.IexCloud.Isins do
  @moduledoc false

  alias Stockcast.Repo
  alias Stockcast.IexCloud.Isin
  alias Stockcast.IexCloud.Api

  @isin_path "ref-data/isin"

  @spec fetch(binary()) :: {:ok, %{deleted: integer(), created: integer()}} | {:error, any()}
  def fetch(isin) when is_binary(isin) do
    case Api.get_data(@isin_path, isin: isin) do
      {:ok, mappings} when is_list(mappings) -> save_isins(isin, mappings)
      {:ok, _} -> {:error, :unexpected_response}
      error -> error
    end
  end

  defp save_isins(isin, mappings) do
    result =
      Enum.reduce(
        mappings,
        %{deleted: 0, created: 0},
        fn %{"iexId" => iex_id}, %{deleted: deleted, created: created} ->
          {:ok, _} = Repo.insert(Isin.changeset(%{isin: isin, iex_id: iex_id}))
          %{deleted: deleted, created: created + 1}
        end
      )

    {:ok, result}
  end
end
