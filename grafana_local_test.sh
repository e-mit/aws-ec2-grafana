#!/bin/bash

# Build and run just the Grafana container locally (not with nginx),
# with either SQLite or Postgres database, and enable the public dashboard.

# Choose database type:
CONFIG=test
# test = use SQLite database in the container
# release = use a PostgreSQL database as specified by the following variables:
export DB_PORT=5432
export DB_USER=grafanauser
export DB_NAME=grafanatest
export DB_HOST=host.docker.internal
# export DB_PASSWORD  # define this if using PostgreSQL
# Note: the DB_* variables are not used with SQLite
# export GF_PASSWORD  # always define this: password to set for Grafana

########################################################################

if [[ -z $GF_PASSWORD ]]; then
    echo ERROR: Please set GF_PASSWORD
    exit 1
fi

docker build --target $CONFIG -t $CONFIG:latest .

docker run -td -p 3000:3000 --name $CONFIG \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e GF_INSTALL_PLUGINS=frser-sqlite-datasource,grafana-clock-panel \
  -e DB_PORT=${DB_PORT} \
  -e DB_USER=${DB_USER} \
  -e DB_NAME=${DB_NAME} \
  -e DB_HOST=${DB_HOST} \
  -e DB_PASSWORD=${DB_PASSWORD} \
  --rm $CONFIG:latest

# Enable public dashboard (cannot be provisioned in files) and print its URL:
DASHBOARD_UID=bdgisvc9bvym8bdashboard  # must match dashboard json file
_attempt_public_dashboard_enable() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} \
    -XPOST "http://localhost:3000/api/dashboards/uid/${DASHBOARD_UID}/public-dashboards" \
    -H "content-type: application/json" --data-raw '{"isEnabled":true}')
}
_attempt_public_dashboard_enable
while [[ "$?" -ne 0 ]]; do
    echo ""
    echo "Waiting for Grafana startup to get dashboard link..."
    echo ""
    sleep 5
    _attempt_public_dashboard_enable
done
DASH_ID=$(printf '%s\n' "$CURL_OUTPUT" | jq -r '.accessToken')
echo ""
echo "Dashboard available at: http://localhost:3000/public-dashboards/$DASH_ID"
echo ""

if [ $CONFIG = "release" ]; then
    # Disable the sslmode of the grafana postgres (only needed for release config)
curl -u admin:${GF_PASSWORD} -X PUT "http://localhost:3000/api/datasources/uid/bdgisvc9bvym8brelease" \
-H "content-type: application/json" --data-raw \
'{"id":1,"uid":"bdgisvc9bvym8brelease","orgId":1,"name":"postgres",'\
'"type":"grafana-postgresql-datasource","typeLogoUrl":'\
'"public/app/plugins/datasource/grafana-postgresql-datasource/img/postgresql_logo.svg",'\
'"access":"proxy","url":"host.docker.internal:5432","user":"grafanauser","database":"",'\
'"basicAuth":false,"basicAuthUser":"","withCredentials":false,"isDefault":true,"jsonData":'\
'{"connMaxLifetime":14400,"database":"grafanatest","maxOpenConns":5,"postgresVersion":1400,'\
'"sslmode":"disable","timescaledb":false},"secureJsonFields":{"password":true},'\
'"version":3,"readOnly":false}' &> /dev/null
fi


python -m pytest test_local_no_nginx.py


# Stop and remove:
# docker stop -t 0 $CONFIG

