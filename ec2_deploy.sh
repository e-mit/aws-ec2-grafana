#!/bin/bash

KEY_FILENAME=../aws-create-db/key.pem
EC2_IP=13.43.90.54

################################################

# Install docker and add ec2-user to the docker group so that sudo is not needed, then log out:
SSH_SCRIPT="
sudo dnf update -y
sudo dnf install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT}"

# NB: can pass in env vars like:
# ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
#    ec2-user@$EC2_IP ENV_VAR=$LOCAL_ENV_VAR "${SSH_SCRIPT}"


# log back in and check that docker is working:
SSH_SCRIPT2="
docker ps
docker --version
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT2}"

