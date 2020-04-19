defmodule Stockcast.IexCloud.Isin do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Stockcast.IexCloud.Symbol

  @isin_format ~r/^[A-Z]{2}\w{9}\d$/

  schema "iexc_isins" do
    field :isin, :string

    belongs_to :symbol, Symbol, foreign_key: :iex_id, references: :iex_id, type: :string
    timestamps(type: :utc_datetime)
  end

  def changeset(symbol \\ %Isin{}, params) do
    symbol
    |> cast(params, [:isin, :iex_id])
    |> validate_required([:isin])
    |> validate_format(:isin, @isin_format)
  end
end
