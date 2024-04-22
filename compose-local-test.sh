#!/bin/bash

# Build and run the test configuration locally. This uses nginx without TLS,
# and can use either a PostgreSQL or SQLite database.

# Choose database type:
GRAFANA_TARGET=test
# test = use SQLite database in the container
# release = use a PostgreSQL database as specified by the following variables:
export DB_PORT=5432
export DB_USER=grafanauser
export DB_NAME=grafanatest
export DB_HOST=host.docker.internal
# export DB_PASSWORD  # define this if using PostgreSQL
# Note: the DB_* variables are not used with SQLite

# Always need the following variables:
export DOMAIN_NAME=localhost
export PUBLIC_PORT=8080
# export GF_PASSWORD  # define this: password to set for Grafana

##############################################

if [[ -z $GF_PASSWORD ]]; then
    echo ERROR: Please set GF_PASSWORD
    exit 1
fi

docker build -f Dockerfile --no-cache --target $GRAFANA_TARGET -t grafana-test:latest .
# The nginx target is always 'test' because this disables TLS:
docker build -f Dockerfile-nginx --no-cache --target test -t nginx-test:latest .

export DASHBOARD_UID=bdgisvc9bvym8bdashboard  # must match dashboard json file
export PUBLIC_PORT_TLS=8443  # Dummy value, not used without TLS
docker compose -f compose-test.yaml up --force-recreate &

_grafana_get() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} \
    -X GET "http://localhost:3000/api/datasources" \
    -H "content-type: application/json")
}
_grafana_get
while [[ "$?" -ne 0 ]]; do
    echo ""
    echo "Waiting for Grafana startup..."
    echo ""
    sleep 5
    _grafana_get
done

if [ $GRAFANA_TARGET = "release" ]; then
# Disable the sslmode of the grafana postgres.
# This is needed when using grafana release without TLS.
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


python -m pytest test_local.py


# docker compose -f compose-test.yaml down
