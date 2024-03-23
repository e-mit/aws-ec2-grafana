#!/bin/sh

docker build -t release:latest .

docker run -d -p 3000:3000 --name release --rm release:latest

# docker stop -t 0 release
