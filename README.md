# AWS EC2 Grafana

![Docker test build](https://github.com/e-mit/aws-ec2-grafana/actions/workflows/docker-test-build.yml/badge.svg)
![local test](https://github.com/e-mit/aws-ec2-grafana/actions/workflows/local-test.yml/badge.svg)

Configure and deploy a Grafana server on AWS EC2 to display a public dashboard with PostgreSQL data.

This project uses Grafana, Nginx, Docker and AWS CLI. All steps are performed using the AWS CLI and shell scripts.

Starting point: an AWS account with:
- An EC2 instance with access to a VPC and with internet access
- A PostgreSQL database on the VPC, without internet access (e.g. hosted on AWS RDS)

View the example deployment at: [https://grafana.e-mit.dev](https://grafana.e-mit.dev)

See also:
- [github.com/e-mit/aws-create-db](https://github.com/e-mit/aws-create-db) for the EC2 and RDS setup
- [github.com/e-mit/aws-lambda-get](https://github.com/e-mit/aws-lambda-get) and [github.com/e-mit/aws-lambda-db](https://github.com/e-mit/aws-lambda-db) for gathering data into the RDS using Lambda functions


### Readme Contents

- **[Overview](#overview)**<br>
- **[Development and testing](#development-and-testing)**<br>
- **[Release build and deployment](#release-build-and-deployment)**<br>


## Overview

- The project builds two Docker containers: Nginx and Grafana.
- The Grafana container provides a public dashboard showing graphs for data in either an in-container SQLite database (for testing), or a remote PostgreSQL database.
- The Nginx container is configured as a reverse proxy, rate limiter and TLS terminator.


## Development and testing

Build and run locally (without AWS interaction), choosing either SQLite or PostgreSQL as data source, using:
- ```grafana_local_test.sh``` for the Grafana container without Nginx
- ```compose-local-test.sh``` for Grafana and Nginx (without TLS)

GitHub Action workflows build, run and test the local SQLite configuration on every push.


## Release build and deployment

1. Build and push to Dockerhub using ```release-build.sh```
2. Do a one-time preparation of the EC2 instance using ```ec2_setup.sh``` - this does the following:
    - Install packages
    - Create an AWS Security Group with inbound TCP permissions
    - Obtain TLS certificates from Let's Encrypt
    - Setup periodic jobs for certificate renewal and security update installation
3. Deploy the project to the EC2 using ```ec2_deploy.sh```

Steps 1 and 3 can be repeated after changes; step 2 is unaffected and does not require repeating.
