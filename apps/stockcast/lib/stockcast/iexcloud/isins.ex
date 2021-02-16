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

  @spec fetch(binary()) :: %{deleted: integer(), created: integer()}
  def fetch!(isin) when is_binary(isin) do
    case fetch(isin) do
      {:ok, result} -> result
      {:error, error} -> raise_exception(error)
      error -> raise_exception(error)
    end
  end

  defp raise_exception(error), do: raise("Error while retrieving isins: #{inspect(error)}")

  defp update_isins(isin, mappings) do
    # TODO: write a test for duplicate symbols in response! 
    unique_mappings =
      mappings
      |> Enum.uniq_by(& &1["symbol"])

    Repo.transaction(fn ->
      {deleted, _} =
        Repo.delete_all(
          from Isin,
            where: [
              isin: ^isin
            ]
        )

      case save_isins(isin, unique_mappings) do
        {:ok, created} -> %{deleted: deleted, created: created}
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  defp save_isins(isin, mappings) when is_list(mappings) and length(mappings) > 0 do
    mappings
    |> Enum.find_value({:ok, length(mappings)}, &save_isin(isin, &1))
  end

  defp save_isins(isin, _) do
    case Repo.insert(Isin.changeset(%{isin: isin})) do
      {:ok, _} -> {:ok, 1}
      error -> error
    end
  end

  defp save_isin(isin, %{"symbol" => symbol}) do
    case Repo.insert(Isin.changeset(%{isin: isin, symbol: symbol})) do
      {:ok, _} -> nil
      error -> error
    end
  end
end
