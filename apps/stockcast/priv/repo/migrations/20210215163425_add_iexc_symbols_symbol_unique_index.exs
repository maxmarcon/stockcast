defmodule Stockcast.Repo.Migrations.AddIexcSymbolsSymbolUniqueIndex do
  use Ecto.Migration

  def change do
    drop index(:iexc_symbols, :symbol)

    create unique_index(:iexc_symbols, :symbol)
  end
end
