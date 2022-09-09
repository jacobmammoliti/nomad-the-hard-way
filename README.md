# Nomad the Hard Way
> **Heavily** inspired by Kelsey Hightower's [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way).

This tutorial walks you through setting up Nomad the hard way. Why is it "the hard way"? It does not use the built-in drivers or network modes Nomad provides and instead looks to the community to bring in those features. There are also no scripts or automation tools used here.

The main drive behind this effort was to learn something new. Hence, Nomad the Hard Way is the result of building a Nomad cluster to better understand Nomad itself and different concepts of containerization including runtime, networking, and storage.

> Containerization workloads are the focus for this exercise. Refer to the [documentation](https://www.nomadproject.io/docs) to see the full capabilities of Nomad.

## In Progress
* Add integration with [GCP Compute Persistent Disk CSI driver](https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver)

## On the Horizon 
* Add lab on integration with the [dnsname](https://github.com/containers/dnsname) CNI plugin for DNS
* Add an Ingress Gateway

## Copyright
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

## Target Audience
The target audience for this tutorial is someone who is interesting in learning more about what goes into building a secure Nomad cluster and get a better understanding of CRIs (Container Runtime Interfaces) and CNIs (Container Network Interfaces).

## Cluster Details
Nomad the Hard Way guides you through bootstrapping a highly available Nomad cluster with end-to-end encryption (Gossip and TLS) between components.

* [nomad](https://github.com/hashicorp/nomad) v1.3.5
* [containerd](https://github.com/containerd/containerd) v1.6.4
* [containerd driver](https://github.com/Roblox/nomad-driver-containerd) v0.9.3
* [cni](https://github.com/containernetworking/cni) v1.0.0

## Labs
The full list of labs can be found here:
* [Prerequisites](docs/01-prerequisites.md)
* [Installing the Client Tools](docs/02-client-tools.md)
* [Provisioning Compute Resources](docs/03-compute-resources.md)
* [Provisioning a CA and Generating TLS Certificates and a Gossip Key](docs/04-certificate-authority.md)
* [Bootstrapping the Nomad Servers](docs/05-bootstrapping-nomad-servers.md)
* [Bootstrapping the Nomad Clients](docs/06-bootstrapping-nomad-clients.md)
* [Provisioning Network Routes](docs/07-network-routes.md)
* [Smoke Test](docs/08-smoke-test.md)
* [Clean Up](docs/09-clean-up.md)