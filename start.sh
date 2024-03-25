#!/bin/bash

# Substitute multiple environment variables in nginx-custom.conf and move it into
# the required directory. Need to provide the individual vars AND the
# "SUBST_VARS" variable which lists them all, for example:
# export VAR1='x'
# export VAR2='y'
# export SUBST_VARS='$VAR1:$VAR2'

# NB: daemon off is needed to run in foreground, preventing docker exit
# Also: subst_vars needs double quotes but if just using var1 directly, use single.
#envsubst "$SUBST_VARS" < /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf && nginx -g 'daemon off;'

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

#export PUBLIC_DASHBOARD_ID=$(printf '%s\n' "$CURL_OUTPUT" | jq -r '.accessToken')
#envsubst '$PUBLIC_DASHBOARD_ID' < /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf && nginx -g 'daemon off;'

export PUBLIC_DASHBOARD_ID=$(printf '%s\n' "$CURL_OUTPUT" | jq -r '.accessToken')
envsubst '$PUBLIC_DASHBOARD_ID:$DOMAIN_NAME' < /nginx-custom.conf > /etc/nginx/conf.d/nginx-custom.conf \
&& nginx -g 'daemon off;'
