defmodule Stockcast.Repo.Migrations.AddIexcIsinsSymbol do
  use Ecto.Migration

  def change do
    alter table("iexc_isins") do
      remove :iex_id, :string

      add :symbol, :string
    end

    create unique_index(:iexc_isins, [:isin, :symbol], name: :iexc_isins_isin_symbol_index)
  end
end
