#!/bin/bash

# Build and run the release configuration (uses
# Postgres database)

docker build -f Dockerfile --target release -t emit5/grafana-release:latest .
docker build -f Dockerfile-nginx -t emit5/nginx-grafana:latest .

docker compose -f compose-release.yaml --env-file env.txt up --force-recreate
