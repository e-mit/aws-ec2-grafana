#!/bin/bash

# This is a one-time setup (per EC2 instance) which does the following:
#  - Install docker and docker compose
#  - Enable docker service to persist across reboot
#  - Create a security policy allowing incoming web requests
#  - Setup TLS and certificate renewal

# Note that docker-compose is not in the AMI dnf package repo, so is obtained
# as exe from docker github. This means it will not be updated with dnf updates.

SSH_KEY_FILENAME=../aws-create-db/key.pem
EC2_ID=i-0a22f77855ffd7af2
DOCKER_COMPOSE_GITHUB="https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64"
DOMAIN_LIST="e-mit.dev,www.e-mit.dev,vat.e-mit.dev,grafana.e-mit.dev"
#EMAIL_ADDRESS  define this

################################################

# Prevent terminal output waiting:
export AWS_PAGER=""

# Get the EC2 public IP address:
EC2_IP=$(aws ec2 describe-instances \
--instance-ids $EC2_ID | \
python3 -c "import sys, json
print(json.load(sys.stdin)['Reservations'][0]['Instances'][0]['PublicIpAddress'])")

# Install docker, add ec2-user to the docker group so that sudo is not needed,
# enable the services required for automatic restart after reboot, then log out:
SSH_SCRIPT="
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo usermod -a -G docker ec2-user
"
ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT}"

# NB: can pass in env vars like:
# ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
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
ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT2}"

# Get the EC2 VPC ID
VPC_ID=$(aws ec2 describe-instances \
--instance-ids $EC2_ID | \
python3 -c "import sys, json
print(json.load(sys.stdin)['Reservations'][0]['Instances'][0]['VpcId'])")

# Create a security group allowing incoming web requests:
SG_ID=$(aws ec2 create-security-group \
--description "Allow inbound access to web server" \
--group-name "webServerGroup" \
--vpc-id "$VPC_ID" | \
python3 -c "import sys, json
print(json.load(sys.stdin)['GroupId'])")

# Add inbound rules
aws ec2 authorize-security-group-ingress \
--group-id $SG_ID \
--ip-permissions \
IpProtocol=tcp,FromPort=80,ToPort=80,\
IpRanges="[{CidrIp=0.0.0.0/0}]",\
Ipv6Ranges="[{CidrIpv6=::/0}]" \
IpProtocol=tcp,FromPort=443,ToPort=443,\
IpRanges="[{CidrIp=0.0.0.0/0}]",\
Ipv6Ranges="[{CidrIpv6=::/0}]" &> /dev/null

# Remove the default outbound rule
aws ec2 revoke-security-group-egress \
--group-id $SG_ID \
--ip-permissions IpProtocol=-1,FromPort=-1,ToPort=-1,IpRanges="[{CidrIp=0.0.0.0/0}]" &> /dev/null

# Get the EC2's current security groups:
SG_LIST=$(aws ec2 describe-instances \
--instance-ids $EC2_ID | \
python3 -c "import sys, json
s = ''
for sg in json.load(sys.stdin)['Reservations'][0]['Instances'][0]['SecurityGroups']:
    s+=(str(sg['GroupId']) + ' ')
print(s)")

# Assign the EC2 to this security group:
aws ec2 modify-instance-attribute \
--instance-id $EC2_ID \
--groups $SG_ID $SG_LIST


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
ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT3}"

# Set a cron job weekly at 2am to (attempt to) renew the certificate.
# Also set a cron job to install security updates every day at 1am.
scp -i $SSH_KEY_FILENAME ec2_cert_renew.sh ec2-user@$EC2_IP:/home/ec2-user/ec2_cert_renew.sh
SSH_SCRIPT4="
sudo dnf update -y
sudo dnf install -y cronie cronie-anacron
sudo crontab -r
sudo systemctl enable crond.service
sudo systemctl start crond.service
sudo rm -f /var/log/ec2_cert_renew.log /var/log/security_updates.log
(sudo crontab -l 2>/dev/null; echo '0 2 * * 1 /home/ec2-user/ec2_cert_renew.sh \
>> /var/log/ec2_cert_renew.log 2>&1') | sudo crontab -
(sudo crontab -l 2>/dev/null; echo '0 1 * * * /usr/bin/dnf upgrade --security \
--assumeyes --releasever=latest \
>> /var/log/security_updates.log 2>&1') | sudo crontab -
"
ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP "${SSH_SCRIPT4}"



if (( 0==1 )); then
# Note: to SSH manually:
ssh -t -i $SSH_KEY_FILENAME -o StrictHostKeyChecking=accept-new \
    ec2-user@$EC2_IP bash
fi
