#!/bin/bash

# Build and run the test configuration locally. This uses nginx without TLS,
# and can use either a PostgreSQL or SQLite database.

# Choose 'test' for SQLite or 'release' for PostgreSQL
GRAFANA_TARGET=test

# Local nginx target should always be 'test' because this disables TLS.

##############################################

docker build -f Dockerfile --no-cache --target $GRAFANA_TARGET -t grafana-test:latest .
docker build -f Dockerfile-nginx --no-cache --target test -t nginx-test:latest .

docker compose -f compose-test.yaml --env-file env.txt up --force-recreate &

echo "Waiting for Grafana to start..."
_grafana_get() {
    CURL_OUTPUT=$(curl -u admin:${GF_PASSWORD} \
    -X GET "http://localhost:3000/api/datasources" \
    -H "content-type: application/json")
}
_grafana_get
while [[ "$?" -ne 0 ]]; do
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
echo ""
echo "READY"
echo ""
else
    source env.txt
    python -m pytest test_*.py
fi


# docker compose -f compose-test.yaml down
