#!/bin/bash

# Build and run the release configuration (uses
# Postgres database)

docker build -f Dockerfile --no-cache --target release -t emit5/grafana-release:latest .
docker build -f Dockerfile-nginx --no-cache -t emit5/nginx-grafana:latest .
docker push emit5/nginx-grafana:latest
docker push emit5/grafana-release:latest

docker compose -f compose-release.yaml --env-file env.txt up --force-recreate
