#!/bin/bash

gcloud dns managed-zones create ${ZONE_NAME} --description "Managed by ExternalDNS" --dns-name ${DNS_DOMAIN}
