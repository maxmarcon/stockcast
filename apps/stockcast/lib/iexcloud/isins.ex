defmodule Stockcast.IexCloud.Isins do
  @moduledoc false

  import Ecto.Query

  alias Stockcast.Repo
  alias Stockcast.IexCloud.Isin
  alias Stockcast.IexCloud.Api

  @isin_path "ref-data/isin"

  @spec fetch(binary()) :: {:ok, %{deleted: integer(), created: integer()}} | {:error, any()}
  def fetch(isin) when is_binary(isin) do
    case Api.get_data(@isin_path, isin: isin) do
      {:ok, mappings} -> update_isins(isin, mappings)
      error -> error
    end
  end

  defp update_isins(isin, mappings) do
    Repo.transaction(fn ->
      {deleted, _} = Repo.delete_all(from Isin, where: [isin: ^isin])
      %{deleted: deleted, created: save_isins(isin, mappings)}
    end)
  end

  defp save_isins(isin, mappings) when is_list(mappings) and length(mappings) > 0 do
    case Enum.reduce_while(
           mappings,
           0,
           &save_isin(isin, &1, &2)
         ) do
      created when is_integer(created) -> created
      error -> Repo.rollback(error)
    end
  end

  defp save_isins(isin, _) do
    with {:ok, _} <- Repo.insert(%Isin{isin: isin}) do
      1
    else
      error -> error
    end
  end

  defp save_isin(isin, %{"iexId" => iex_id}, created) do
    case Repo.insert(Isin.changeset(%{isin: isin, iex_id: iex_id})) do
      {:ok, _} -> {:cont, created + 1}
      {:error, changeset} -> {:halt, changeset}
    end
  end
end
