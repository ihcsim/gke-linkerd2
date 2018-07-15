# GKE-101
This repository contains scripts that I used to manage my GKE cluster.

## Repository Layout
The `infra` folder contains a set of bash scripts for creating the custom VPC, subnets, firewall rules and GKE cluster.

The `apps` folder contains the following applications used for testing the cluster:
* nginx - 3-replica deployment with a load balancer service
* cockroachdb - 3-replica statefulset with dynamic storage provisioning
