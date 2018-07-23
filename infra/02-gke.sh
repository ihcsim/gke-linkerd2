#!/bin/bash

NETWORK=${NETWORK:-main}
GKE_REGION=${GKE_REGION:-us-west1}
GKE_VERSION=${GKE_VERSION:-1.10.5-gke.0}

CLUSTER_NAME=${CLUSTER_NAME:-main}
CLUSTER_IPV4_CIDR=172.16.0.0/15
CLUSTER_SECONDARY_RANGE_NAME=pod-range
SERIVCES_IPV4_CIDR=10.100.0.0/19
SERVICES_SECONDARY_RANGE_NAME=service-range

NODES_MIN=${NODE_MIN:-2}
NODES_MAX=${NODE_MAX:-10}

gcloud container clusters create ${CLUSTER_NAME} \
  --addons=HttpLoadBalancing,HorizontalPodAutoscaling,NetworkPolicy \
  --cluster-ipv4-cidr=${CLUSTER_IPV4_CIDR} \
  --cluster-secondary-range-name=${CLUSTER_SECONDARY_RANGE_NAME} \
  --enable-ip-alias \
  --cluster-version=${GKE_VERSION} \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-cloud-logging \
  --enable-cloud-monitoring \
  --enable-ip-alias  \
  --enable-network-policy \
  --network=${NETWORK} \
  --node-version=${GKE_VERSION} \
  --num-nodes=${NODES_MIN} \
  --services-ipv4-cidr=${SERVICES_IPV4_CIDR} \
  --services-secondary-range-name=${SERVICES_SECONDARY_RANGE_NAME} \
  --subnetwork=main \
  --enable-autoscaling \
  --max-nodes=${NODES_MAX} \
  --min-nodes=${NODES_MIN} \
  --region=${GKE_REGION}

# create a node pool with DNS scoped node.
# use for external-dns pods only.
gcloud beta container node-pools create external-dns-pool --cluster=${CLUSTER_NAME} \
  --region=${GKE_REGION} \
  --enable-autorepair \
  --enable-autoupgrade \
  --num-nodes=1 \
  --scopes="default,https://www.googleapis.com/auth/ndev.clouddns.readwrite,https://www.googleapis.com/auth/cloud-platform" \
  --node-labels="managed-dns=true"
  --node-taints="managed-dns=true:NoSchedule"

# allow SSH from my IP
FIRST_NODE=`kubectl get no -o jsonpath='{.items[0].metadata.name}'`
NODES_TAG=`gcloud compute instances describe ${FIRST_NODE} --format='value(tags.items[0])'`
MY_PUBLIC_IPV4=`curl ipinfo.io/ip`

gcloud compute firewall-rules create gke-${NETWORK}-allow-ssh \
  --network=${NETWORK} \
  --allow=tcp:22 \
  --target-tags=${NODES_TAG} \
  --source-ranges=${MY_PUBLIC_IPV4}/32
