# Bootstrapping the Nomad Clients
In this lab you will bootstrap the Nomad clients across three compute instances. The following components will be installed on each node: nomad, [containerd](https://github.com/containerd/containerd), [containerd task driver](https://github.com/Roblox/nomad-driver-containerd) and [container network plugins](https://github.com/containernetworking/plugins).

## Prerequisites
The commands in this lab must be run on each controller instance: `nomad-client-0`, `nomad-client-1`, `nomad-client-2`. Login to each server instance using the `gcloud` command. Example:
```bash
gcloud compute ssh nomad-client-0
```

### Running commands in parallel with tmux
If you are looking to run these commands in parallel, Kelsey Hightower shows [how to use tmux](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md#running-commands-in-parallel-with-tmux) to do this.

## Provision the Nomad Clients
Install the OS dependencies:
```bash
sudo apt-get update

sudo apt-get install unzip
```

### Download the Client Binaries
```bash
wget -q --show-progress --https-only --timestamping \
  https://releases.hashicorp.com/nomad/1.3.0/nomad_1.3.0_linux_amd64.zip \
  https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz \
  https://github.com/Roblox/nomad-driver-containerd/releases/download/v0.9.3/containerd-driver
```

### Install the Nomad Binary
Unzip and install the Nomad binary:
```bash
unzip nomad_1.3.0_linux_amd64.zip

sudo chown root: nomad 

sudo mv nomad /usr/local/bin
```

### Configure the Client
Create a dedicated Linux user for Nomad:
```bash
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
```

Create the neccessary directories for Nomad:
```bash
sudo mkdir --parents /opt/nomad/plugins

sudo mkdir --parents /etc/nomad.d/tls

sudo mkdir --parents /opt/cni/config

sudo mkdir /opt/cni/bin

sudo chown -R nomad: /opt/nomad

sudo chown -R nomad: /etc/nomad.d
```

Copy the certificates to the TLS directory:
```bash
sudo mv ca.pem client.pem client-key.pem /etc/nomad.d/tls

sudo chown nomad: /etc/nomad.d/tls/*

sudo chmod 600 /etc/nomad.d/tls/*
```

### Install Containderd and runc
Use apt to install Containerd and inherently runc:
```bash
sudo apt-get install containerd
```

Install containerd task driver:
```bash
sudo mv containerd-driver /opt/nomad/plugins

sudo chown nomad: /opt/nomad/plugins/*

sudo chmod 600 /opt/nomad/plugins/*

sudo chmod u+x /opt/nomad/plugins/containerd-driver
```

### Configure CNI Networking
Retrieve the container CIDR range for the current compute instance:
```bash
CONTAINER_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/container-cidr)
```

Create the `bridge` network configuration file:
```bash
cat <<EOF | sudo tee /opt/cni/config/10-bridge.conflist
{
  "cniVersion": "1.0.0",
  "name": "bridge",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${CONTAINER_CIDR}"}]
        ],
      "routes": [{"dst": "0.0.0.0/0"}]
    }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      },
      "snat": true
    }
  ]
}
EOF
```

Install the CNI drivers:
```bash
sudo tar -xvf cni-plugins-linux-amd64-v1.1.1.tgz -C /opt/cni/bin
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
User=root
Group=root

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

### Configure the Client Configuration
Create a client configuration file:
```bash
sudo bash -c 'cat << EOF > /etc/nomad.d/client.hcl
client {
  enabled = true

  server_join {
    retry_join = ["provider=gce tag_value=server"]
  }

  cni_path       = "/opt/cni/bin"
  cni_config_dir = "/opt/cni/config"
}

plugin "containerd-driver" {
  config {
    enabled            = true
    containerd_runtime = "io.containerd.runc.v2"
    stats_interval     = "5s"
  }
}

tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/tls/ca.pem"
  cert_file = "/etc/nomad.d/tls/client.pem"
  key_file  = "/etc/nomad.d/tls/client-key.pem"

  verify_server_hostname = true
  verify_https_client    = false
}
EOF'

sudo chown nomad: /etc/nomad.d/client.hcl

sudo chmod 660 /etc/nomad.d/client.hcl
```

### Start the Nomad Clients
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

Next: [Provisioning Network Routes](07-network-routes.md)