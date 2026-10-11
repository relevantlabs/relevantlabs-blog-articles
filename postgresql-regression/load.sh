#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

source "./include.sh"

load() {
  export PGSERVICEFILE
  export PGSERVICE

  psql \
    --single-transaction \
    --set "ON_ERROR_STOP=1" \
    --file "${setup_sql_file}"

  vacuumdb \
    --analyze \
    --full \
    --schema "public" \
    --dbname "service=${PGSERVICE}" 
}

echo "Loading data..."
load
