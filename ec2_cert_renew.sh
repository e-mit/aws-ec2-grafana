#!/bin/bash

# Renew expiring letsencrypt certificate(s)
# This is required every 3 months, but OK to run
# every week.

docker container stop -t 0 nginx
sleep 20

sudo docker run -it --rm --name certbot \
    -p "80:80" \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    certbot/certbot:latest renew

docker container start nginx
