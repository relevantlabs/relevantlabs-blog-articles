#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

declare -r data_dir="./download"
declare -r -a source_sql_files=(
  "aggregates.sql"
  "arrays.sql"
  "create_index.sql"
  "jsonb.sql"
  "test_setup.sql"
  "tsearch.sql"
)
declare -r setup_sql_file="${data_dir}/sample-data-setup.sql"
declare -r index_sql_file="${data_dir}/create-index.sql"

declare -r github_url="https://raw.githubusercontent.com/postgres/postgres/refs/heads/REL_18_STABLE/src/test/regress"

declare -r PGSERVICEFILE="./pg_service.conf"
declare -r PGSERVICE="regression"
