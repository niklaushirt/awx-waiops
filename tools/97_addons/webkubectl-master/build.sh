#!/bin/bash

export CONT_VERSION=0.5


# Build Production AMD64
docker buildx build --platform linux/amd64 -t niklaushirt/cp4waiops-tools:$CONT_VERSION --load .
docker push niklaushirt/cp4waiops-tools:$CONT_VERSION




# Local Test Mac
docker build -t niklaushirt/cp4waiops-install:arm$CONT_VERSION .
#sudo docker push cp4waiops-install:arm$CONT_VERSION
docker run -p 8080:8080 cp4waiops-install:arm$CONT_VERSION




# Create the Image
docker buildx build --platform linux/arm64,linux/amd64 -t niklaushirt/cp4waiops-tools:arm --load -f Dockerfile.arm .
docker push niklaushirt/cp4waiops-tools:arm
docker run -ti --rm -p 22:22000 niklaushirt/cp4waiops-tools:arm /bin/bash

# Run the Image
docker run -p 8080:8080 -e KAFKA_TOPIC=$KAFKA_TOPIC -e KAFKA_USER=$KAFKA_USER -e KAFKA_PWD=$KAFKA_PWD -e KAFKA_BROKER=$KAFKA_BROKER -e CERT_ELEMENT=$CERT_ELEMENT niklaushirt/cp4waiops-demo-ui:$CONT_VERSION

# Deploy the Image
oc apply -n default -f create-cp4mcm-event-gateway.yaml

