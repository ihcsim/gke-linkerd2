#!/bin/bash

NETWORK=${NETWORK:-main}

# allow all internal
gcloud compute firewall-rules create ${NETWORK}-allow-internal \
  --network=${NETWORK} \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/8

# allow http and https
gcloud compute firewall-rules create ${NETWORK}-allow-web \
  --network=${NETWORK} \
  --allow=tcp:80,tcp:443
