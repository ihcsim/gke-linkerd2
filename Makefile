.PHONY: infra nginx cockroachdb conduit-cli

GKE_REGION ?= us-west1
GKE_VERSION ?= 1.10.5-gke.0
GKE_NODE_MIN ?= 2
GKE_NODE_MAX ?= 10

NETWORK ?= main

infra:
	NETWORK=$(NETWORK) ./infra/00-network.sh
	NETWORK=$(NETWORK) ./infra/01-firewalls.sh
	NETWORK=$(NETWORK) GKE_REGION=$(GKE_REGION) GKE_VERSION=$(GKE_VERSION) NODE_MIN=$(GKE_NODE_MIN) NODE_MAX=$(GKE_NODE_MAX) ./infra/02-gke.sh

conduit:
	./infra/03-conduit.sh

conduit-cli:
	curl https://run.conduit.io/install | sh

conduit-dashboard:
	conduit dashboard

nginx:
	conduit inject apps/nginx.yaml | kubectl apply -f - --record

nginx-delete:
	kubectl delete -f apps/nginx.yaml

cockroachdb:
	conduit inject apps/cockroachdb.yaml | kubectl apply -f - --record

cockroachdb-delete:
	kubectl delete -f apps/cockroachdb.yaml
