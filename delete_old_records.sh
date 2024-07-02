#!/bin/bash

# Script to delete database entries older than 2 months.

# Requires a .pgpass file containing:
# your_psql_host:5432:your_database_name:your_psql_username:your_psql_password
# and set PGPASSFILE with the path to the file.

# PostgreSQL credentials and host information
PSQL_USER="dbuser"
PSQL_HOST="testdbi.cvyycu2kubso.eu-west-2.rds.amazonaws.com"
PSQL_DB="postgres"
PSQL_TABLE="carbonintensityrecord"
export PGPASSFILE=/home/ec2-user/.pgpass

# Delete records older than 2 months
DELETE_QUERY="DELETE FROM $PSQL_TABLE WHERE time < NOW() - INTERVAL '2 months';"

# Execute the delete query
psql -U $PSQL_USER -h $PSQL_HOST -d $PSQL_DB -c "$DELETE_QUERY"
