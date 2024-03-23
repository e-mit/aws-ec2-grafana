#!/bin/bash

docker build --target release -t release:latest .

docker run -td -p 3000:3000 --name release \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e GF_INSTALL_PLUGINS=grafana-clock-panel \
  -e TEST_DB_PORT=${TEST_DB_PORT} \
  -e TEST_DB_USER=${TEST_DB_USER} \
  -e TEST_DB_NAME=${TEST_DB_NAME} \
  -e TEST_DB_HOST=${TEST_DB_HOST} \
  -e TEST_DB_PASSWORD=${TEST_DB_PASSWORD} \
  --add-host host.docker.internal:host-gateway \
  --rm release:latest

# Enable public dashboard (cannot be provisioned in files) and print its URL:
DASHBOARD_UID=bdgisvc9bvym8bdashboardrelease  # must match dashboard json file
_attempt_public_dashboard_enable() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} -XPOST "http://localhost:3000/api/dashboards/uid/${DASHBOARD_UID}/public-dashboards" -H "content-type: application/json" --data-raw '{"isEnabled":true}')
}
_attempt_public_dashboard_enable
while [[ "$?" -ne 0 ]]; do
    sleep 5
    _attempt_public_dashboard_enable
done
printf '%s\n' "$CURL_OUTPUT" | python3 -c \
"import sys, json
id = json.load(sys.stdin)['accessToken']
print(f'http://localhost:3000/public-dashboards/{id}')"


# docker exec release ls
# docker stop -t 0 release
