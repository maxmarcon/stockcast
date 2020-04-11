defmodule Stockcast.Repo.Migrations.CreateSymbols do
  use Ecto.Migration

  def change do
    create table("iexc_symbols") do
      add :symbol, :string, null: false
      add :exchange, :string
      add :name, :string, null: false
      add :date, :date, null: false
      add :type, :string, null: false
      add :iex_id, :string, null: false
      add :region, :string, size: 2, null: false
      add :currency, :string, size: 3, null: false
      add :figi, :string
      add :cik, :string

      timestamps()
    end

    create unique_index(:iexc_symbols, :iex_id)
  end
end
