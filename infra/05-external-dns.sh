#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
cat ${SCRIPT_PATH}/../apps/external-dns.yaml | linkerd inject - | kubectl apply -f -
