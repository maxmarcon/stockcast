# Stockcast

Visualize, analyze and predict stock prices

## Data source

Stockcast uses the [IEX Cloud API](https://iexcloud.io/) to retrieve financial data.

## Installation and Set-up

You will need to [sign up with IEX Cloud](https://iexcloud.io/cloud-login#/register/) and obtain an API token (yes, they do have a rather generous free access plan).

### Running locally with mix in dev or sandbox mode

*Dev mode* runs against the real IEX Cloud production API, whereas *sandbox mode* runs against the IEX Cloud sandbox 
 and doesn't consume your account's API calls. The downside being that the data is fake.

Prerequisites:

* Elixir >=1.10
* Mix and Hex installed
* Docker
* Node 13.7.0

After having cloned the repository, do the following:

* `cp secret.template.exs dev.secret.exs`
    * Uncomment the lines in `dev.secret.exs` and replace `#{YOUR_TOKEN_HERE}` with your IexCloud production token
* `cp secret.template.exs sandbox.secret.exs`
    * Uncomment the lines in `dev.secret.exs` and replace `#{YOUR_TOKEN_HERE}` with your IexCloud sandbox token
* Start the development database with: `docker-compose -f apps/stockcast/docker-compose.yaml up -d`

The following commands will execute in dev mode. 
If you want to run in sandbox mode you should set anx export the environment
variable `MIX_ENV=sandbox`

* Setup the database: 
    * `cd apps/stockcast`
    * `mix ecto.setup`
    * `cd ../../`
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
