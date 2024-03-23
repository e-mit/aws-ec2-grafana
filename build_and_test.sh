#!/bin/sh

docker build -t test:latest .

# The -td forces the container to keep running without any CMD, and as a daemon
docker run -td -p 3000:3000 --name test \
  -e GF_SECURITY_ADMIN_PASSWORD=${GF_PASSWORD} \
  -e GF_INSTALL_PLUGINS=frser-sqlite-datasource,grafana-clock-panel \
  --rm test:latest

# do tests here. Run command like:
# docker exec test python -m mypy . --exclude 'tests/' --exclude 'venv/'
# docker exec test sh -c 'python -m pycodestyle *.py --exclude=tests/*,venv/*'

# docker stop -t 0 test
