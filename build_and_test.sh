#!/bin/bash

docker build --target test -t test:latest .

docker run -td -p 3000:3000 --name test \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e GF_INSTALL_PLUGINS=frser-sqlite-datasource,grafana-clock-panel \
  --rm test:latest


# do tests here. Run command like:
# docker exec test python -m mypy . --exclude 'tests/' --exclude 'venv/'
# docker exec test sh -c 'python -m pycodestyle *.py --exclude=tests/*,venv/*'


# Enable public dashboard (cannot be provisioned in files) and print its URL:
DASHBOARD_UID=bdgisvc9bvym8bdashboardtest  # must match dashboard json file
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



# docker stop -t 0 test
