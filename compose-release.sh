#!/bin/bash

# Build and run the release configuration (uses
# Postgres database)

# export GF_PASSWORD  # define this
export DASHBOARD_UID=bdgisvc9bvym8bdashboard
export DOMAIN_NAME=localhost
export NGINX_PORT=8080
export DB_PORT=5432
export DB_USER=grafanauser
export DB_NAME=grafanatest
export DB_HOST=host.docker.internal
# export DB_PASSWORD  # define this

docker compose -f compose-release.yaml up --build --force-recreate
