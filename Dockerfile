# syntax=docker/dockerfile:1

FROM grafana/grafana-enterprise:10.4.1 as base

WORKDIR /

COPY . .
COPY dashboard.yaml /etc/grafana/provisioning/dashboards/dashboard.yaml
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /global-bundle.pem
USER root
RUN chmod a+r /global-bundle.pem

FROM base as release
# Data from PostgreSQL database
COPY datasource-release.yaml /etc/grafana/provisioning/datasources/datasource-release.yaml
COPY dashboard-release.json /etc/grafana/provisioning/dashboards/dashboard-release.json

FROM base as test
# Data from local SQLite database
COPY datasource-test.yaml /etc/grafana/provisioning/datasources/datasource-test.yaml
COPY dashboard-test.json /etc/grafana/provisioning/dashboards/dashboard-test.json
