#!/bin/bash

export CONT_VERSION=cp4waiops-awx

docker buildx build --platform linux/amd64 -t niklaushirt/cp4waiops-tools:$CONT_VERSION --load -f Dockerfile.awx .
docker push niklaushirt/cp4waiops-tools:$CONT_VERSION