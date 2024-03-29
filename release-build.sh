#!/bin/bash

# Build and push the release configuration

docker build -f Dockerfile --no-cache --target release -t emit5/grafana-release:latest .
docker build -f Dockerfile-nginx --no-cache -t emit5/nginx-grafana:latest .
docker push emit5/nginx-grafana:latest
docker push emit5/grafana-release:latest
