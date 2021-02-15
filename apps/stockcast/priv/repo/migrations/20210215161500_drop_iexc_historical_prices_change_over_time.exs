defmodule Stockcast.Repo.Migrations.DropIexcHistoricalPricesChangeOverTime do
  use Ecto.Migration

  def change do
    alter table("iexc_historical_prices") do
      remove :changeOverTime, :decimal
    end
  end
end
