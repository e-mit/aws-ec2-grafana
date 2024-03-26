#!/bin/bash

# Build and run the test configuration (uses
# SQLite database within the grafana container)

docker build -f Dockerfile --target test -t emit5/grafana-test:latest .
docker build -f Dockerfile-nginx -t emit5/nginx-grafana:latest .

docker compose -f compose-test.yaml --env-file env.txt up --force-recreate
