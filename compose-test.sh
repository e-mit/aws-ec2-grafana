#!/bin/bash

# Build and run the test configuration (uses
# SQLite database within the grafana container)

# export GF_PASSWORD  # define this
export DASHBOARD_UID=bdgisvc9bvym8bdashboard
export DOMAIN_NAME=localhost
export NGINX_PORT=8080

###################################################

docker build -f Dockerfile --target test -t emit5/grafana-test:latest .
docker build -f Dockerfile-nginx -t emit5/nginx-grafana:latest .

docker compose -f compose-test.yaml up --force-recreate
