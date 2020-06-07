# Stockcast

Visualize, analyze and predict stock prices

## Data source

Stockcast uses the [IEX Cloud API](https://iexcloud.io/) to retrieve financial data.

## Installation and Set-up

You will need to [sign up with IEX Cloud](https://iexcloud.io/cloud-login#/register/) and obtain an API token (yes, they do have a rather generous free access plan).

### Running locally with mix in dev mode

Prerequisites:

* Elixir >=1.10
* Mix and Hex installed
* Docker
* Node 13.7.0

After having cloned the repository, do the following:

* `cp secret.template.exs dev.secret.exs`
* Uncomment the lines in `dev.secret.exs` and replace `#{YOUR_TOKEN_HERE}` with your IexCloud sandbox token
  * Alternatively, you can use the production token if you want to but you'll have to also change the `base_url` in `dev.exs` to `https://cloud.iexapis.com/v1`
* Start the development database with: `docker-compose -f apps/stockcast/docker-compose.yaml up -d`
* Run the migrations with: `mix migrate`
* Run `mix fetch.symbols` to fetch the list of available financial securities from IEX Cloud. This might take a while.
  The sets of securities that will be fetched is configured in `config/config.exs` unde `Stockcast.IexCloud.Symbols` as a list of API endpoints.
  This results in a total of about 75k securities being installed.
  You can modify the list, and you can work your way through the available API endpoints for financial symbols [here](https://iexcloud.io/docs/api/#reference-data).
* Start the server with `mix phx.server`
* In another terminal, build and start the single page web application: 
  * `cd stockcast_spa`
  * `nvm use` to set the right node version to use (you might have to install, again using nvm)
  * `yarn`
  * `yarn serve`
* Access the application at `http://localhost:8080`

### Running with docker

Prerequisites:

* Docker

After having cloned the repository, do the following:

* In `docker-compose.yml`, replace `#{YOUR_TOKEN_HERE}` with your IexCloud production token
* Run `docker-compose up`
* Be patient...
* After a while, your application will be available at `http://localhost:4002`

## Testing

If you want to see some unit tests running, do the following:

* Start the development database with: `docker-compose -f apps/stockcast/docker-compose.yaml up -d`
* Run: `mix test`

For the backend tests, and:

* `cd stockcast_spa`
* `yarn test`

For the front-end tests.
