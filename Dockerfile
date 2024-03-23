# syntax=docker/dockerfile:1

FROM grafana/grafana-enterprise:10.4.1 as base

WORKDIR /

COPY . .

COPY dashboard.yaml /etc/grafana/provisioning/dashboards/dashboard.yaml
COPY dashboard.json /etc/grafana/provisioning/dashboards/dashboard.json

COPY datasource-test.yaml /etc/grafana/provisioning/datasources/datasource-test.yaml
