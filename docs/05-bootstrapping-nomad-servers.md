# Bootstrapping the Nomad Servers
In this lab you will bootstrap the Nomad servers across three compute instances and configure it for high availability. You will also need to create an external load balancer that exposes the Nomad API to remote clients. The following components will be installed on each node: `nomad`.

## Prerequisites
The commands in this lab must be run on each controller instance: `nomad-server-0`, `nomad-server-1`, `nomad-server-2`. Login to each server instance using the `gcloud` command. Example:
```bash
gcloud compute ssh nomad-server-0
```

### Running commands in parallel with tmux
If you are looking to run these commands in parallel, Kelsey Hightower shows [how to use tmux](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md#running-commands-in-parallel-with-tmux) to do this.

```bash
tmux new -s servers

Ctrl+b %

Ctrl+b %

Ctrl+b <- # move left

Ctrl+b ^ # move up

Ctrl+b :set synchronize-panes on

Ctrl+b :set synchronize-panes off
```

## Provision the Nomad Servers
Install the OS dependencies:
```bash
sudo apt-get update

sudo apt-get install -y unzip jq
```

### Download and Install the Nomad Binary
```bash
export NOMAD_VERSION=1.3.5
```

Download the official Nomad release binary:
```bash
wget -q --show-progress --https-only --timestamping \
  https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/nomad_"$NOMAD_VERSION"_linux_amd64.zip
```

Unzip and install the Nomad binary:
```bash
unzip nomad_"$NOMAD_VERSION"_linux_amd64.zip

sudo chown root: nomad 

sudo mv nomad /usr/local/bin
```

### Create Nomad User and Configure the Server
Create a dedicated Linux user for Nomad:
```bash
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
```

Create the neccessary directories for Nomad:
```bash
sudo mkdir --parents /opt/nomad

sudo mkdir --parents /etc/nomad.d/tls

sudo chown nomad: /opt/nomad

sudo chown -R nomad: /etc/nomad.d
```

Copy the certificates to the TLS directory:
```bash
sudo mv ca.pem server.pem server-key.pem /etc/nomad.d/tls

sudo chown nomad: /etc/nomad.d/tls/*

sudo chmod 600 /etc/nomad.d/tls/*
```

### Configure the systemd Unit file
Create a Nomad service file:
```bash
sudo bash -c 'cat << EOF > /lib/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=nomad
Group=nomad

ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2

TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF'
```

### Configure the Common Configuration
Create a common configuration file that is used for both Servers and Clients:
```bash
sudo bash -c 'cat << EOF > /etc/nomad.d/nomad.hcl
datacenter = "dc1"
data_dir = "/opt/nomad"
EOF'

sudo chown nomad: /etc/nomad.d/nomad.hcl

sudo chmod 660 /etc/nomad.d/nomad.hcl
```

### Configure the Server Configuration
Set your Gossip key generated in the previous section:
```bash
export GOSSIP_KEY=<YOUR_GOSSIP_KEY>
```

Create a sever configuration file:

> Note: Ensure you replace your Gossip key generated in the previous section

```bash
sudo bash -c 'cat << EOF > /etc/nomad.d/server.hcl
server {
  enabled          = true
  bootstrap_expect = 3
  encrypt          = "${GOSSIP_KEY}"

  server_join {
    retry_join = ["provider=gce tag_value=server"]
  }
}

acl {
  enabled = true
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/tls/ca.pem"
  cert_file = "/etc/nomad.d/tls/server.pem"
  key_file  = "/etc/nomad.d/tls/server-key.pem"

  verify_server_hostname = true
  verify_https_client    = false
}
EOF'

sudo chown nomad: /etc/nomad.d/server.hcl

sudo chmod 660 /etc/nomad.d/server.hcl
```

### Start the Nomad Servers
Enable and start the Nomad service:
```bash
sudo systemctl enable nomad
```

```bash
sudo systemctl start nomad
```

Check the status:
```bash
sudo systemctl status nomad
```

## The Nomad Frontend Load Balancer
In this section you will provision an external load balancer to front the Nomad Servers. The `nomad-the-hard-way` static IP address will be attached to the resulting load balancer.

> **Note:** The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances and only run it once.

### Provision a Network Load Balancer
Create the external load balancer network resources:

```bash
NOMAD_PUBLIC_ADDRESS=$(gcloud compute addresses list \
  --filter="name=('nomad-the-hard-way')" \
  --format="value(address)")

gcloud compute target-pools create nomad-target-pool

gcloud compute target-pools add-instances nomad-target-pool \
  --instances-zone us-central1-a \
  --instances nomad-server-0,nomad-server-1,nomad-server-2

gcloud compute forwarding-rules create nomad-forwarding-rule \
  --address ${NOMAD_PUBLIC_ADDRESS} \
  --ports 4646 \
  --region $(gcloud config get-value compute/region) \
  --target-pool nomad-target-pool
```

### Verification and Bootstrap
Retrieve the `nomad-the-hard-way` static IP address:
```bash
NOMAD_PUBLIC_ADDRESS=$(gcloud compute addresses list \
  --filter="name=('nomad-the-hard-way')" \
  --format="value(address)")
```

Set required environment variables:
```bash
export NOMAD_SKIP_VERIFY=true # Needed unless you trust the CA you created earlier
export NOMAD_ADDR=https://${NOMAD_PUBLIC_ADDRESS}:4646
```

Bootstrap the ACL system:
```bash
nomad acl bootstrap
```

> output

```bash
Accessor ID  = 13a3dbfc-4be7-c57f-1423-c4f0e6e0c5c4
Secret ID    = a9268b1a-a3ab-7547-f5d1-24a498a9fc2d
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2022-05-21 23:16:03.389801948 +0000 UTC
Create Index = 220
Modify Index = 220
```

Export the token as an environment variable:
```bash
export NOMAD_TOKEN="a9268b1a-a3ab-7547-f5d1-24a498a9fc2d"
```

Validate the cluster:
```bash
nomad server members
```

> output
```bash
Name                   Address      Port  Status  Leader  Raft Version  Build  Datacenter  Region
nomad-server-0.global  10.240.0.10  4648  alive   true    3             1.3.0  dc1         global
nomad-server-1.global  10.240.0.11  4648  alive   false   3             1.3.0  dc1         global
nomad-server-2.global  10.240.0.12  4648  alive   false   3             1.3.0  dc1         global
```

## Create an Anonymous ACL Policy
Grant clients a basic level of access without needing to provide an ACL token. Create an Anonymous policy:

> **Note:** This is a **very** open policy and should likely be scoped down in production environments.

```bash
cat <<EOF > anonymous.policy.hcl
namespace "*" {
  policy       = "write"
  capabilities = ["alloc-node-exec"]
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

node {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}
EOF
```

Apply the anonymous policy:
```bash
nomad acl policy apply \
  -description "Anonymous policy (full-access)" \
  anonymous anonymous.policy.hcl
```

> output
```bash
Successfully wrote "anonymous" ACL policy!
```

Unset the token environment variable and validate we can see the members:
```bash
unset NOMAD_TOKEN

nomad server members
```

Open the Nomad UI:
```bash
nomad ui
````

Next: [Bootstrapping the Nomad Clients](06-bootstrapping-nomad-clients.md)