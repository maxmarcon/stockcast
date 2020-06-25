defmodule Stockcast.Repo.Migrations.AddIexcSymbolsSymbolIndex do
  use Ecto.Migration

  def change do
    create index(:iexc_symbols, :symbol)
  end
end   
