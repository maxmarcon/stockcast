defmodule Stockcast.Repo.Migrations.CreateIsins do
  use Ecto.Migration

  def change do
    create table("iexc_isins") do
      add :isin, :string, null: false
      add :iex_id, :string

      timestamps()
    end

    create unique_index(:iexc_isins, [:isin, :iex_id], name: :iexc_isins_isin_iex_id_index)
  end
end
