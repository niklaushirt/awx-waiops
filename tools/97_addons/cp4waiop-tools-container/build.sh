#!/bin/bash

export CONT_VERSION=0.5


sudo docker build -t niklaushirt/cp4waiops-tools:$CONT_VERSION .
sudo docker push niklaushirt/cp4waiops-tools:$CONT_VERSION

docker buildx build --platform linux/amd64 -t niklaushirt/cp4waiops-tools:$CONT_VERSION --load .
sudo docker push niklaushirt/cp4waiops-tools:$CONT_VERSION


# Create the Image
docker buildx build --platform linux/arm64,linux/amd64 -t niklaushirt/cp4waiops-tools:arm --load -f Dockerfile.arm .
docker push niklaushirt/cp4waiops-tools:arm
docker run -ti --rm -p 22:22000 niklaushirt/cp4waiops-tools:arm /bin/bash

# Run the Image
docker run -p 8080:8080 -e KAFKA_TOPIC=$KAFKA_TOPIC -e KAFKA_USER=$KAFKA_USER -e KAFKA_PWD=$KAFKA_PWD -e KAFKA_BROKER=$KAFKA_BROKER -e CERT_ELEMENT=$CERT_ELEMENT niklaushirt/cp4waiops-demo-ui:$CONT_VERSION

# Deploy the Image
oc apply -n default -f create-cp4mcm-event-gateway.yaml



docker run -it --rm quay.io/openshift/origin-cli:latest

exit 1

docker run -d --rm --name microshift --privileged -v microshift-data:/var/lib -p 6443:6443 quay.io/microshift/microshift-aio:latest

docker exec -ti microshift oc get all -A

docker cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ./kubeconfig
oc get all -A --kubeconfig ./kubeconfig

oc apply --kubeconfig ./kubeconfig -n default -f create-tool.yaml

k9s --kubeconfig ./kubeconfig

