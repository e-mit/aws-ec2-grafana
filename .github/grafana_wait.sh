#!/bin/bash

# wait for the grafana server to start
_grafana_get() {
    CURL_OUTPUT=$(curl -u admin:admin \
    -X GET "http://localhost:3000/api/datasources" \
    -H "content-type: application/json")
}
_grafana_get
while [[ "$?" -ne 0 ]]; do
    sleep 5
    _grafana_get
done
sleep 5
