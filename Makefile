MY_PUBLIC_IPV4=$(shell dig +short myip.opendns.com @resolver1.opendns.com)

GKE_REGION ?= us-west1
GKE_VERSION ?= 1.10.5-gke.0
GKE_NODE_MIN ?= 2
GKE_NODE_MAX ?= 10

NETWORK ?= main
CLUSTER_NAME ?= main

.PHONY: infra
infra:
	NETWORK=$(NETWORK) ./infra/00-network.sh
	NETWORK=$(NETWORK) ./infra/01-firewalls.sh
	NETWORK=$(NETWORK) GKE_REGION=$(GKE_REGION) GKE_VERSION=$(GKE_VERSION) NODE_MIN=$(GKE_NODE_MIN) NODE_MAX=$(GKE_NODE_MAX) CLUSTER_NAME=$(CLUSTER_NAME) ./infra/02-gke.sh

infra/managed-zones:
	ZONE_NAME=$(ZONE_NAME) DNS_DOMAIN=$(DNS_DOMAIN) ./infra/04-managed-dns.sh

infra/external-dns:
	./infra/05-external-dns.sh

infra/external-dns-delete:
	kubectl delete -f apps/external-dns.yaml

linkerd2:
	./infra/03-linkerd2.sh

linkerd2-cli:
	curl https://run.conduit.io/install | sh

linkerd2-dashboard:
	linkerd dashboard

.PHONY: apps/nginx
apps/nginx:
	kubectl apply -f apps/nginx --record
	gcloud compute firewall-rules create gke-$(NETWORK)-allow-http-nginx --network=$(NETWORK) --allow=tcp:32065 --source-ranges=$(MY_PUBLIC_IPV4)/32

.PHONY: apps/nginx/policies
apps/nginx/policies:
	kubectl apply -f apps/nginx/policies --record

apps/nginx-delete:
	kubectl delete -f apps/nginx
	gcloud compute firewall-rules delete gke-$(NETWORK)-allow-http-nginx

apps/cockroachdb:
	linkerd inject apps/cockroachdb.yaml | kubectl apply -f - --record

apps/cockroachdb-delete:
	kubectl delete -f apps/cockroachdb.yaml

apps/emojivoto:
	linkerd inject apps/emojivoto.yaml | kubectl apply -f - --record
	gcloud compute firewall-rules create gke-$(NETWORK)-allow-http-emojivoto --network=$(NETWORK) --allow=tcp:32067 --source-ranges=$(MY_PUBLIC_IPV4)/32

apps/emojivoto-delete:
	kubectl delete -f apps/emojivoto.yaml
	gcloud compute firewall-rules delete gke-$(NETWORK)-allow-http-emojivoto

apps/redis:
	linkerd inject apps/redis.json | kubectl apply -f - --record

apps/redis-delete:
	kubectl delete -f apps/redis.json

apps/guestbook:
	linkerd inject apps/guestbook.json | kubectl apply -f - --record

apps/guestbook-delete:
	kubectl delete -f apps/guestbook.json

.PHONY: apps/stars
apps/stars:
	kubectl apply -f apps/stars --record

.PHONY: apps/stars-delete
apps/stars-delete:
	kubectl delete -f apps/stars

apps/stars/network-policies:
	kubectl apply -f apps/stars/policies/deny-all.yaml --record
	kubectl apply -f apps/stars/policies/allow-from-ui.yaml --record
	kubectl apply -f apps/stars/policies/allow-frontend-to-backend.yaml --record
	kubectl apply -f apps/stars/policies/allow-client-to-frontend.yaml --record

apps/tiller:
	kubectl create serviceaccount tiller -n kube-system
	kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	helm init --service-account=tiller --dry-run --debug | linkerd inject - | kubectl apply -f -

apps/tiller-delete:
	kubectl delete deploy,svc -l name=tiller -n kube-system
