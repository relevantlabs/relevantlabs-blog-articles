# Recreating PostgreSQL Sample Tables from Regression Tests

Bash script used in my blog page [Recreating PostgreSQL Sample Tables from Regression Tests](https://www.relevantlabs.pl/).

## Usage

Extract (download) the tables definitions and data files from the PostgreSQL GitHub repository.

```bash
bash ./extract.sh
```

Execute the generated SQL script, which creates the tables in the local database and loads the data into them.

```bash
bash ./load.sh
```

## Project tree

`./postgresql-regression`
 * [curl.conf`](./postgresql-regression/curl.conf) - `curl` configuration file
 * [`extract.awk`](./postgresql-regression/extract.awk) - `gawk` script
 * [`pg_service.conf`](./postgresql-regression/pg_service.conf) - PostgreSQL connection configuration file
 * [`extract.sh`](./postgresql-regression/extract.sh) - Bash script used for extracting (downloading) SQL and data files from the PostgreSQL repository
 * [`load.sh`](./postgresql-regression/load.sh) - Bash script used for uploading the table definitions and data files into a local PostgreSQL database
 * [`include.sh`](./postgresql-regression/include.sh) - common variables and functions used by the `extract.sh` and `load.sh` Bash scripts
