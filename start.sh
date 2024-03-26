#!/bin/bash

# This file does 3 things:
# - Wait for the Grafana container to run, then enable its public dashboard.
# - Substitute environment variables in the nginx config.
# - Start nginx

# Substitute (multiple) environment variable(s) in nginx-custom.conf and move it
# into the required directory. Need to provide the individual vars AND the
# "SUBST_VARS" variable which lists them all, for example:
# export VAR1='x'
# export VAR2='y'
# export SUBST_VARS='$VAR1:$VAR2'
# SUBST_VARS needs double quotes in the following line; use single quotes if listing the vars directly.
#envsubst "$SUBST_VARS" < /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf && nginx -g 'daemon off;'
#envsubst '$VAR1:$VAR2' < /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf && nginx -g 'daemon off;'

# Nginx 'daemon off' is needed to run it in foreground, preventing docker exit.

_attempt_public_dashboard_enable() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} \
    -XPOST "http://grafana:3000/api/dashboards/uid/${DASHBOARD_UID}/public-dashboards" \
    -H "content-type: application/json" --data-raw '{"isEnabled":true}')
}
_attempt_public_dashboard_enable
while [[ "$?" -ne 0 ]]; do
    sleep 5
    _attempt_public_dashboard_enable
done

export PUBLIC_DASHBOARD_ID=$(printf '%s\n' "$CURL_OUTPUT" | jq -r '.accessToken')
envsubst '$PUBLIC_DASHBOARD_ID:$DOMAIN_NAME:$NGINX_PORT' \
< /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf \
&& nginx -g 'daemon off;'
