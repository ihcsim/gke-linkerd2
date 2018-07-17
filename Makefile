.PHONY: infra nginx cockroachdb conduit-cli

MY_PUBLIC_IPV4=$(shell dig +short myip.opendns.com @resolver1.opendns.com)

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

apps/nginx:
	conduit inject apps/nginx.yaml | kubectl apply -f - --record
	gcloud compute firewall-rules create gke-$(NETWORK)-allow-http-nginx --network=$(NETWORK) --allow=tcp:32065 --source-ranges=$(MY_PUBLIC_IPV4)/32

apps/nginx-delete:
	kubectl delete -f apps/nginx.yaml
	gcloud compute firewall-rules delete gke-$(NETWORK)-allow-http-nginx

apps/cockroachdb:
	conduit inject apps/cockroachdb.yaml | kubectl apply -f - --record

apps/cockroachdb-delete:
	kubectl delete -f apps/cockroachdb.yaml

apps/emojivoto:
	conduit inject apps/emojivoto.yaml | kubectl apply -f - --record
	gcloud compute firewall-rules create gke-$(NETWORK)-allow-http-emojivoto --network=$(NETWORK) --allow=tcp:32067 --source-ranges=$(MY_PUBLIC_IPV4)/32

apps/emojivoto-delete:
	kubectl delete -f apps/emojivoto.yaml
	gcloud compute firewall-rules delete gke-$(NETWORK)-allow-http-emojivoto
