#!/bin/bash

# (Re)start the latest version of the project on the target EC2.
# This assumes that ec2_setup.sh has already been run once.

KEY_FILENAME=../aws-create-db/key.pem
EC2_IP=13.43.90.54
ENV_FILE=./env-ec2.txt
USER=ec2-user
COMPOSE_FILE=compose-release.yaml

################################################

SSH_SCRIPT="
for filename in /home/$USER/project/*.yaml; do
    docker compose -f \$filename down
done
rm -rf /home/$USER/project
mkdir /home/$USER/project
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    $USER@$EC2_IP "${SSH_SCRIPT}"

scp -i $KEY_FILENAME $ENV_FILE $USER@$EC2_IP:/home/$USER/project/env-ec2.txt
scp -i $KEY_FILENAME $COMPOSE_FILE $USER@$EC2_IP:/home/$USER/project/$COMPOSE_FILE

SSH_SCRIPT2="
cd /home/$USER/project
docker compose -f $COMPOSE_FILE pull
docker compose -f $COMPOSE_FILE --env-file env-ec2.txt up --force-recreate --detach
rm -f env-ec2.txt
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    $USER@$EC2_IP "${SSH_SCRIPT2}"
