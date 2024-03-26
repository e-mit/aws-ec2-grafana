#!/bin/bash

# Build and run the test configuration (uses
# SQLite database within the grafana container)

# export GF_PASSWORD  # define this
export DASHBOARD_UID=bdgisvc9bvym8bdashboard
export DOMAIN_NAME=localhost
export NGINX_PORT=8080

docker compose -f compose-test.yaml up --build --force-recreate
