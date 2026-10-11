#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

source "./include.sh"

#
# Download sql files, extract the path and download the corresponding data
# files from the GutHub repository.
#
download_files() {
  local sql_file="${1}"
  local output_sql_file="${data_dir}/sql/${sql_file}"

  echo "Downloading ${sql_file}..."
  curl \
    --config "./curl.conf" \
    --output "${output_sql_file}" \
    "${github_url}/sql/${sql_file}"

  echo "Extracting data file paths from the sql file..."
  while IFS= read -r data_file_path; do
    echo "Downloading $(basename ${data_file_path})..."
    curl \
      --config "./curl.conf" \
      --output "${data_dir}${data_file_path}" \
      "${github_url}${data_file_path}"
    echo "${data_file_path}" >> "${data_dir}/data-files.txt"
  done < <(awk --file="./extract.awk" "${output_sql_file}")

  # Remove duplicates from data-files.txt file
  gawk \
    --include inplace \
    '!seen[$0]++' \
    "${data_dir}/data-files.txt"
}


#
# Extract CREATE TABLE syntax for a defined table from
# the downloaded sql files.
#
extract_create_table() {
  local table_name="${1}"

  grep \
    --only-matching \
	--no-filename \
	--recursive \
	--null-data \
    --perl-regexp \
    "CREATE TABLE ${table_name}\b[^;]*;" \
	"${data_dir}/sql" || {
	  # Handle the grep's exit code 1 ("no match")
	  # but fail on actual grep errors
      local status=$?
      (( status == 1 )) || return "${status}"
    }
}

#
# Generate \copy command a defined table using one of 
# the downloaded data files.
#
get_copy_sql() {
  local table_name="${1}"
  local data_path="${data_dir}${2}"

  printf "\\copy %s from '%s'\n" "${table_name}" "${data_path}"
}

#
# Extract CREATE TABLE and generate a corresponding \copy command
# to load the data into the table.
#
extract_create_table_copy_commands() {

  while IFS= read -r data_path; do
    table_name="$(basename "${data_path%.data}")"
    # Extract table names
    case "${table_name}" in
      agg)
        extract_create_table "aggtest" >> "${setup_sql_file}"
		get_copy_sql "aggtest" "${data_path}" >> "${setup_sql_file}"
        ;;
      array)
        extract_create_table "array_index_op_test" >> "${setup_sql_file}"
		get_copy_sql "array_index_op_test" "${data_path}" >> "${setup_sql_file}"
		extract_create_table "array_op_test" >> "${setup_sql_file}"
		get_copy_sql "array_op_test" "${data_path}" >> "${setup_sql_file}"
        ;;
      jsonb)
        extract_create_table "testjsonb" >> "${setup_sql_file}"
		get_copy_sql "testjsonb" "${data_path}" >> "${setup_sql_file}"
        ;;
      onek)
        extract_create_table "onek"  >> "${setup_sql_file}"
		get_copy_sql "onek" "${data_path}" >> "${setup_sql_file}"
		extract_create_table "onek2" >> "${setup_sql_file}"
        ;;
      rect)
        extract_create_table "slow_emp4000" >> "${setup_sql_file}"
		get_copy_sql "slow_emp4000" "${data_path}" >> "${setup_sql_file}"
        ;;
      streets)
        extract_create_table "road" >> "${setup_sql_file}"
		get_copy_sql "road" "${data_path}" >> "${setup_sql_file}"
		extract_create_table "ihighway" >> "${setup_sql_file}"
		extract_create_table "shighway" >> "${setup_sql_file}"
        ;;
      tenk)
        extract_create_table "tenk1" >> "${setup_sql_file}"
		get_copy_sql "tenk1" "${data_path}" >> "${setup_sql_file}"
		extract_create_table "tenk2" >> "${setup_sql_file}"
        ;;
      tsearch)
        extract_create_table "test_tsvector" >> "${setup_sql_file}"
		get_copy_sql "test_tsvector" "${data_path}" >> "${setup_sql_file}"
        ;;
      *)
        extract_create_table "${table_name}" >> "${setup_sql_file}"
		get_copy_sql "${table_name}" "${data_path}" >> "${setup_sql_file}"
        ;;
    esac
  done < "${data_dir}/data-files.txt"

  # Replace NUL separators produced by grep --null-data with newlines.
  sed --in-place 's/\x0/\n/g' "${setup_sql_file}"
  # Add IF NOT EXISTS clause to CREATE TABLE.
  sed --in-place '/IF NOT EXISTS/! s/CREATE TABLE /CREATE TABLE IF NOT EXISTS /g' "${setup_sql_file}"
}

#
# Extract CREATE INDEX statements from the source sql files and save them
# in a separate file.
#
extract_create_index_commands() {

  for table_name in $(grep \
      --only-matching \
      --perl-regexp \
	  "(?<=CREATE TABLE IF NOT EXISTS )[a-z_]+[0-9]*" \
	  "${setup_sql_file}" | \
	  sort --unique
	); do
    grep \
      --only-matching \
      --perl-regexp \
	  --null-data \
	  --no-filename \
	  --recursive \
	"CREATE INDEX .*ON ${table_name}[[:space:]]+[^;]*;" \
	"${data_dir}/sql" >> "${index_sql_file}" || {
	  # Handle the grep's exit code 1 ("no match")
	  # but fail on actual grep errors
      local status=$?
      (( status == 1 )) || return "${status}"
    }
  done

  # Replace NUL separators produced by grep --null-data with newlines.
  sed --in-place 's/\x0/\n/g' "${index_sql_file}"
}

#
# Main function
#
extract() {
  # Create missing directories
  if ! [[ -d "${data_dir}" ]]; then
    mkdir --parents "${data_dir}"
  fi

  # Empty target files
  : > "${data_dir}/data-files.txt"
  : > "${setup_sql_file}"
  : > "${index_sql_file}"

  for source_sql_file in "${source_sql_files[@]}"; do
    echo "Processing ${source_sql_file}..."
    download_files "${source_sql_file}"

  done

  # Generate sql file header
  cat << SQL | tee --append "${setup_sql_file}" "${index_sql_file}"
-- Begin $(date)
SQL

  echo "Extracting CREATE TABLE and \copy commands from SQL files..."
  extract_create_table_copy_commands

  echo "Extracting CREATE INDEX commands from SQL files..."
  extract_create_index_commands

  # Generate sql file footer
  cat << SQL | tee --append "${setup_sql_file}" "${index_sql_file}"
-- End $(date)
SQL

  # Cleanup after successful run
  rm --force "${data_dir}/data-files.txt"
}

extract
