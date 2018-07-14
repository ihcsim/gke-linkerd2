#!/bin/bash

NETWORK=main
NEWORK_MODE=${NETWORK_MODE}

REGIONS=(us-west1 us-west2 us-east1 us-east4)

declare -A PRIMARY_IPV4_RANGE_CIDR
PRIMARY_IPV4_RANGE_CIDR=([us_west_1]=10.0.0.0/16 [us_west_2]=10.10.0.0/16 [us_east_1]=10.20.0.0/16 [us_east_4]=10.30.0.0/16)

declare -A SECONDARY_IPV4_RANGE_POD_CIDR
SECONDARY_IPV4_RANGE_POD_CIDR=([us_west_1]=172.16.0.0/20 [us_west_2]=172.17.0.0/20 [us_east_1]=172.18.0.0/20 [us_east_4]=172.19.0.0/20)

declare -A SECONDARY_IPV4_RANGE_SERVICE_CIDR
SECONDARY_IPV4_RANGE_SERVICE_CIDR=([us_west_1]=10.100.0.0/20 [us_west_2]=10.100.16.0/20 [us_east_1]=10.100.32.0/20 [us_east_4]=10.100.48.0/20)

SECONDARY_IPV4_RANGE_NAME_POD=pod-range
SECONDARY_IPV4_RANGE_NAME_SERVICE=service-range

# vpc
gcloud compute networks create ${NETWORK} --subnet-mode=${NETWORK_MODE}

# subnets
for region in "${REGIONS[@]}"; do
  primary_ipv4_range_cidr=${PRIMARY_IPV4_RANGE_CIDR[$region]}
  secondary_ipv4_range_pod_cidr=${SECONDARY_IPV4_RANGE_POD_CIDR[$region]}
  secondary_ipv4_range_service_cidr=${SECONDARY_IPV4_RANGE_SERVICE_CIDR[$region]}

  gcloud compute networks subnets create ${NETWORK} \
    --network ${NETWORK} \
    --region ${REGION} \
    --range ${primary_ipv4_range_cidr} \
    --enable-private-ip-google-access \
    --secondary-range ${SECONDARY_IPV4_RANGE_NAME_POD}=${secondary_ipv4_range_pod_cidr},${SECONDARY_IPV4_RANGE_NAME_SERVICE}=${secondary_ipv4_range_service_cidr}
done

# allow all internal
gcloud compute firewall-rules create ${NETWORK}-allow-internal \
  --network=${NETWORK} \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/8

# allow http and https
gcloud compute firewall-rules create ${NETWORK}-allow-web \
  --network=${NETWORK} \
  --allow=tcp:80,tcp:443
