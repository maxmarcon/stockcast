# Stockcast

Visualize, analyze and predict stock prices

## Data source

Stockwatch uses the [IEX Cloud API](https://iexcloud.io/) to retrieve financial data.

## Installation and Set-up

You will need to [sign up with IEX Cloud](https://iexcloud.io/cloud-login#/register/) and obtain an API token (yes, they do have a rather generous free access plan).

Other prerequisites:

* Elixir >=1.10
* Mix and Hex installed
* Docker

After having cloned the repository and obtained an API token, do the following:

* TODO: where to install the API token
* Run: `mix deps.get`
* Start the database with: `docker-compose -f apps/stockcast/docker-compose.yaml up`
* Run the migrations with: `mix migrate`
* Run `mix fetch.symbols` to fetch the list of available financial securities from IEX Cloud. This might take a while.
  The sets of securities that will be fetched is configured in `config/config.exs` unde `Stockcast.IexCloud.Symbols` as a list of API endpoints.
  This results in a total of about 75k securities being installed.
  You can modify the list, and you can work your way through the available API endpoints for financial symbols [here](https://iexcloud.io/docs/api/#reference-data).

## Testing

If you want to see some unit tests running, run:

* `mix test`


