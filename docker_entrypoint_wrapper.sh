#!/usr/bin/env bash
# This script waits for the DB to be up and runs the migrations (if any need to run)
# before launching the application
DB_TIMEOUT=${DB_TIMEOUT:-45}

RELEASE_SCRIPT=$1
SYMBOLS_FETCHED=symbols_fetched

export DATABASE_URL
export IEXCLOUD_API_TOKEN

# Why this assignment here? Because ENV SECRET_KEY_BASE=$(mix phx.gen.secret) does not work
# (the output of a command can't be used to set an environment variable)
export SECRET_KEY_BASE=$(mix phx.gen.secret)

DB_ENDPOINT=$(echo $DATABASE_URL | awk 'match($0, /.*\@(\w+:[0-9]+)\/?/, g) {print g[1]}')
if [ -z $DB_ENDPOINT ]; then
	echo "DATABASE_URL appears to be invalid: $DATABASE_URL" >&2
	exit 1
fi

if (wait-for-it $DB_ENDPOINT -t $DB_TIMEOUT); then
  $RELEASE_SCRIPT eval 'Application.ensure_all_started(:stockcast); \
  Ecto.Migrator.run(Stockcast.Repo, :up, all: true)'
  [ ! -e $SYMBOLS_FETCHED ] \
  && $RELEASE_SCRIPT eval 'Application.ensure_all_started(:stockcast); \
  Mix.Tasks.Fetch.Symbols.run([])' \
  && touch $SYMBOLS_FETCHED
	exec $*
else
	echo "Error: database at: [$DB_ENDPOINT] not ready after waiting for $DB_TIMEOUT seconds" >&2
	exit 1
fi
