# Provisioning Compute Resources
Nomad requires a set of machines to host the Nomad Servers and Clients (where jobs run). In this lab you will provision the compute resources required across a single availability zone.

## Networking
### Virtual Private Cloud Network
In this section a dedicated [Virtual Private Cloud](https://cloud.google.com/vpc) (VPC) network will be setup to host the Nomad cluster.

Create the `nomad-the-hard-way` custom VPC network:
```bash
gcloud compute networks create nomad-the-hard-way --subnet-mode custom
```

A subnet must be provisioned with an IP address range large enough to assign a private IP address to each node in the Nomad cluster.
Create the `nomad` subnet in the `nomad-the-hard-way` VPC network:
```bash
gcloud compute networks subnets create nomad \
  --network nomad-the-hard-way \
  --range 10.240.0.0/24
```
> **Note:** The 10.240.0.0/24 IP address range can host up to 254 compute instances.

### Firewall Rules
Create a firewall rule that allows internal communication across all protocols:
```bash
gcloud compute firewall-rules create nomad-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network nomad-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
```

Create a firewall rule that allows external SSH, ICMP, and HTTPS:
```bash
gcloud compute firewall-rules create nomad-the-hard-way-allow-external \
  --allow tcp:22,tcp:4646,icmp \
  --network nomad-the-hard-way \
  --source-ranges 0.0.0.0/0
```

> **Note:** An [external load balancer](https://cloud.google.com/load-balancing/docs/https) will be used to expose the Nomad servers to remote clients.

List the firewall rules in the `nomad-the-hard-way` VPC network:
```bash
gcloud compute firewall-rules list --filter="network:nomad-the-hard-way"
```

> output
```bash
NAME                               NETWORK             DIRECTION  PRIORITY  ALLOW                 DENY  DISABLED
nomad-the-hard-way-allow-external  nomad-the-hard-way  INGRESS    1000      tcp:22,tcp:4646,icmp        False
nomad-the-hard-way-allow-internal  nomad-the-hard-way  INGRESS    1000      tcp,udp,icmp                False
```

### Nomad Public IP Address
Allocate a static IP address that will be attached to the external load balancer fronting the Nomad servers:
```bash
gcloud compute addresses create nomad-the-hard-way \
  --region $(gcloud config get-value compute/region)
```

Verify the `nomad-the-hard-way` static IP address was created in your default compute region:
```bash
gcloud compute addresses list --filter="name=('nomad-the-hard-way')"
```

> output
```bash
NAME                ADDRESS/RANGE  TYPE      PURPOSE  NETWORK  REGION       SUBNET  STATUS
nomad-the-hard-way  XX.XXX.XX.XXX  EXTERNAL                    us-central1          RESERVED
```

Note the IP address for the IP SAN later:
```bash
export NOMAD_PUBLIC_ADDRESS=$(gcloud compute addresses list \
  --filter="name=('nomad-the-hard-way')" \
  --format="value(address)")
```

## Service Account
Create a dedicated service account that will be used for both Nomad servers and clients.
```bash
gcloud iam service-accounts create nomad-sa

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:nomad-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role "roles/compute.viewer"
```

## Compute Instances
The compute instances in this lab will be provisioned using Ubuntu Server 20.04, which has good support for the containerd container runtime. Each compute instance will be provisioned with a fixed private IP address to be explicit in the Nomad configuration when specifying the `bind_addr`.

### Nomad Servers
Create three compute instances which will host the Nomad Servers:
```bash
for i in 0 1 2; do
  gcloud compute instances create nomad-server-${i} \
    --async \
    --boot-disk-size 100GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip 10.240.0.1${i} \
    --scopes cloud-platform \
    --subnet nomad \
    --service-account nomad-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com \
    --tags nomad-the-hard-way,server
done
```

### Nomad Clients
Each worker instance requires a subnet allocation for jobs. The subnet allocation will be used to configure container networking in a later exercise. The `container-cidr` instance metadata will be used to expose subnet allocations to compute instances at runtime.

Create three compute instances which will host the Nomad Clients:
```bash
for i in 0 1 2; do
  gcloud compute instances create nomad-client-${i} \
    --async \
    --boot-disk-size 100GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --metadata container-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes cloud-platform \
    --subnet nomad \
    --service-account nomad-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com \
    --tags nomad-the-hard-way,client
done
```

### Verification
List the compute instances in your default compute zone:
```bash
gcloud compute instances list --filter="tags.items=nomad-the-hard-way"
```

> output
```bash
NAME            ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
nomad-client-0  us-central1-a  e2-standard-2               10.240.0.20  XX.XXX.XX.X     RUNNING
nomad-client-1  us-central1-a  e2-standard-2               10.240.0.21  XX.XXX.X.XXX    RUNNING
nomad-client-2  us-central1-a  e2-standard-2               10.240.0.22  XX.XXX.XXX.XXX  RUNNING
nomad-server-0  us-central1-a  e2-standard-2               10.240.0.10  XX.XXX.XXX.XXX  RUNNING
nomad-server-1  us-central1-a  e2-standard-2               10.240.0.11  XX.XXX.XX.XXX   RUNNING
nomad-server-2  us-central1-a  e2-standard-2               10.240.0.12  XX.XXX.XXX.XXX  RUNNING
```

### Configuring SSH Access
SSH will be used to configure the Server and Client instances. When connecting to compute instances for the first time SSH keys will be generated for you and stored in the project or instance metadata as described in the [connecting to instances](https://cloud.google.com/compute/docs/instances/connecting-to-instance) documentation.

Test SSH access to the `nomad-client-0` compute instances:
```bash
gcloud compute ssh nomad-client-0
```

After the SSH keys have been updated you'll be logged into the `nomad-client-0` instance:
```bash
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.13.0-1024-gcp x86_64)
...
```

Type `exit` at the prompt to exit the `nomad-client-0` compute instance:
```bash
$USER@nomad-client-0:~$ exit
```

> output
```bash
logout
Connection to XX.XXX.XX.X closed
```

Next: [Provisioning a CA and Generating TLS Certificates and a Gossip Key](04-certificate-authority.md)