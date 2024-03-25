#!/bin/bash

# Substitute multiple environment variables in nginx.conf and move it into
# the required directory. Need to provide the individual vars AND the
# "SUBST_VARS" variable which lists them all, for example:
# export VAR1='x'
# export VAR2='y'
# export SUBST_VARS='$VAR1:$VAR2'

# NB: daemon off is needed to run in foreground, preventing docker exit
#envsubst "$SUBST_VARS" < /nginx.conf > /etc/nginx/conf.d/nginx.conf && nginx -g 'daemon off;'
envsubst '$GRAFANA_ADDR_PORT' < /nginx.conf > /etc/nginx/conf.d/nginx.conf && nginx -g 'daemon off;'
