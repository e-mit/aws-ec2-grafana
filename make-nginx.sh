#!/bin/bash

docker build -f Dockerfile-nginx -t nginx-test:latest .

docker tag nginx-test:latest emit5/nginx-test:latest

docker push emit5/nginx-test:latest

