#!/bin/bash

# Build and run the Grafana release container alone, and
# enables the public dashboard.

export DB_PORT=5432
export DB_USER=grafanauser
export DB_NAME=grafanatest
export DB_HOST=host.docker.internal
# export DB_PASSWORD  # define separately
# export GF_PASSWORD  # define separately

docker build --target release -t release:latest .

docker run -td -p 3000:3000 --name release \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e DB_PORT=${DB_PORT} \
  -e DB_USER=${DB_USER} \
  -e DB_NAME=${DB_NAME} \
  -e DB_HOST=${DB_HOST} \
  -e DB_PASSWORD=${DB_PASSWORD} \
  --rm release:latest

# Enable public dashboard (cannot be provisioned in files) and print its URL:
DASHBOARD_UID=bdgisvc9bvym8bdashboard  # must match dashboard json file
_attempt_public_dashboard_enable() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} \
    -XPOST "http://localhost:3000/api/dashboards/uid/${DASHBOARD_UID}/public-dashboards" \
    -H "content-type: application/json" --data-raw '{"isEnabled":true}')
}
_attempt_public_dashboard_enable
while [[ "$?" -ne 0 ]]; do
    sleep 5
    _attempt_public_dashboard_enable
done
DASH_ID=$(printf '%s\n' "$CURL_OUTPUT" | jq -r '.accessToken')
echo "Dashboard available at: http://localhost:3000/public-dashboards/$DASH_ID"

# docker stop -t 0 release


# Note on docker push
# Always tag twice: version number and latest: then can easily pull latest
# docker build -t reg/user/image:ver -t reg/user/image:latest .
# (nb: can also build then tag later)
# docker push reg/user/image --all-tags
