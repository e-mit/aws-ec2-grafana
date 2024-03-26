#!/bin/bash

# This builds and runs the Grafana test container alone, and
# enables the public dashboard.

docker build --target test -t test:latest .

docker run -td -p 3000:3000 --name test \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e GF_INSTALL_PLUGINS=frser-sqlite-datasource,grafana-clock-panel \
  --rm test:latest


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

# docker stop -t 0 test
