#!/bin/bash

# Build and run the test configuration (uses
# SQLite database within the grafana container)

docker build -f Dockerfile --no-cache --target test -t emit5/grafana-test:latest .
docker build -f Dockerfile-nginx --no-cache -t emit5/nginx-grafana:latest .
docker push emit5/nginx-grafana:latest
docker push emit5/grafana-test:latest

docker compose -f compose-test.yaml --env-file env.txt up --force-recreate
