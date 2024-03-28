#!/bin/bash

# This is a one-time setup (per EC2 instance) which does the following:
#  - Install docker and docker compose
#  - Enable docker service to persist across reboot
#  - Create a security policy allowing incoming web requests
#  - Setup TLS

# Note that docker-compose is not in the AMI dnf package repo, so is obtained
# as exe from docker github. This means it will not be updated with dnf updates.

KEY_FILENAME=../aws-create-db/key.pem
EC2_IP=13.43.90.54
DOCKER_COMPOSE_GITHUB="https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64"
DOMAIN_LIST="e-mit.dev,www.e-mit.dev,vat.e-mit.dev,grafana.e-mit.dev"
#EMAIL_ADDRESS  define this

################################################

# Install docker, add ec2-user to the docker group so that sudo is not needed,
# enable the services required for automatic restart after reboot, then log out:
SSH_SCRIPT="
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo usermod -a -G docker ec2-user
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT}"

# NB: can pass in env vars like:
# ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
#    ec2-user@$EC2_IP ENV_VAR=$LOCAL_ENV_VAR "${SSH_SCRIPT}"

# log back in, download and install docker-compose (not in distro repo)
# as described at https://docs.docker.com/compose/install/linux/#install-the-plugin-manually
SSH_SCRIPT2="
DOCKER_CONFIG=\${DOCKER_CONFIG:-\$HOME/.docker}
mkdir -p \$DOCKER_CONFIG/cli-plugins
curl -SL $DOCKER_COMPOSE_GITHUB \
-o \$DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x \$DOCKER_CONFIG/cli-plugins/docker-compose
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT2}"


# TODO: Create a security policy allowing incoming web requests


# Setup TLS: multiple subdomains get saved into one certificate path.
# All generated keys/certificates go into: /etc/letsencrypt/live/$first_domain_name
# This folder contains privkey.pem, fullchain.pem, etc
# - the nginx variable "ssl_certificate_key" must point to privkey.pem
# - the nginx variable "ssl_certificate" must point to fullchain.pem
# Also: all certbot config goes into /etc/letsencrypt, so it is OK to
# remove the container afterwards.
SSH_SCRIPT3="
sudo docker run -it --rm --name certbot \
-p "80:80" \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
certbot/certbot:latest certonly --standalone \
-d $DOMAIN_LIST \
-m $EMAIL_ADDRESS --agree-tos --no-eff-email -n
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT3}"

# now set a cron job to renew the certificate




if (( 0==1 )); then
# Note: to SSH manually:
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP bash
fi
