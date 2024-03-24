#!/bin/bash
# Install docker and run a web app container on an already-existing EC2 instance.
# Note that the EC2 instance must have a policy to allow incoming web requests.
# Also note: docker-compose is not in the AMI dnf package repo, so is installed
# from docker github. This means it will not be updated with dnf updates.

KEY_FILENAME=../aws-create-db/key.pem
EC2_IP=13.43.90.54
DOCKER_CONTAINER_IMAGE="emit5/grafana-test:latest"
# GF_SECURITY_ADMIN_PASSWORD  # define this
DOCKER_COMPOSE_GITHUB="https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64"

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


# download the container image, and run it (with restart option):
SSH_SCRIPT3="
docker pull $DOCKER_CONTAINER_IMAGE
docker run -d -p 3000:3000 --name grafana-test \
-e GF_SECURITY_ADMIN_PASSWORD=$GF_SECURITY_ADMIN_PASSWORD \
-e GF_INSTALL_PLUGINS=frser-sqlite-datasource,grafana-clock-panel \
--restart=always $DOCKER_CONTAINER_IMAGE
"
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT3}"

# NB: can still stop and delete the container (not the image) with:
# docker stop -t 0 <name>
# docker container rm <name>


if (( 0==1 )); then
# Note: to SSH manually:
ssh -t -i $KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP bash
fi
