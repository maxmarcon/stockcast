defmodule Stockcast.IexCloud.Isin do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Stockcast.IexCloud.Symbol

  @isin_format ~r/^[A-Z]{2}\w{9}\d$/

  defimpl Jason.Encoder, for: Isin do
    def encode(isin, opts) do
      Jason.Encode.string(isin.isin, opts)
    end
  end

  schema "iexc_isins" do
    field :isin, :string

    belongs_to :for_symbol, Symbol, foreign_key: :symbol, references: :symbol, type: :string
    timestamps(type: :utc_datetime)
  end

  def changeset(isin \\ %Isin{}, params) do
    isin
    |> cast(params, [:isin, :symbol])
    |> validate_required([:isin])
    |> validate_format(:isin, @isin_format)
    |> unique_constraint(:isin, name: :iexc_isins_isin_symbol_index)
  end
end
