#!/bin/bash

# This (re)installs and starts the latest version of the project on the target EC2.
# This assumes that ec2_setup.sh has already been run once.

KEY_FILENAME=../aws-create-db/key.pem
EC2_IP=13.43.90.54
GITHUB_PROJECT_LINK="https://github.com/e-mit/aws-ec2-grafana"

################################################

SSH_SCRIPT="
rm -rf project
git clone $GITHUB_PROJECT_LINK project
./project/compose-release.sh
"

ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT}"
