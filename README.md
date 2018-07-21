# GKE-Conduit
This repository contains scripts that I used to test [conduit](https://conduit.io) on my GKE cluster.

## Getting Started
Provision a GCP custom VPC in 4 regions (us-west1, us-west2, us-east1, us-east2) and a GKE cluster:
```
$ make infra
```

Install conduit CLI:
```
$ make conduit-cli
```

Install conduit:
```
$ make conduit
```

Deploy applications:
```
$ make apps/nginx
$ make apps/cockroachdb
$ make apps/emojivoto
```

## Repository Layout
The `infra` folder contains a set of bash scripts for creating the custom VPC, subnets, firewall rules and GKE cluster.

The `apps` folder contains the following applications used for testing the cluster:
* nginx ([src](https://docs.projectcalico.org/v3.1/getting-started/kubernetes/tutorials/advanced-policy)) - 3-replica deployment with a load balancer service and network policies
* cockroachdb - 3-replica statefulset with dynamic storage provisioning
* emojivoto ([src](https://raw.githubusercontent.com/runconduit/conduit-examples/master/emojivoto/emojivoto.yml)) - an emoji votes web application with an ingress frontend
* guestbook + redis ([src](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)) - the guestbook application from the EKS _Getting Started_ docs
* stars ([src](https://docs.projectcalico.org/v3.1/getting-started/kubernetes/tutorials/stars-policy/)) - the Calico _stars policy_ demo

## Clean Up
Delete applications:
```
$ make apps/nginx-delete
$ make apps/cockroachdb-delete
$ make apps/emojivoto-delete
```
