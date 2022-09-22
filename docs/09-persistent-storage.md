# Adding Persistent Storage
So far the workloads you have deployed are stateless. To deploy a stateful workload, like a database, 

In this lab you will deploy the [GCE Persistent Disk CSI Driver](https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver) and deploy a sample stateful workload to validate persistent storage.

## Bind Propagation Mode Issue
At this time, the `containerd` driver [does not support bind propagation](https://github.com/Roblox/nomad-driver-containerd/issues/140). Therefore, this lab will use the Docker driver which requires installing Docker on the clients and adding a new config stanza in the `client.hcl` file.

> **Note:** These steps need only to be done on the clients not the servers.

Install Docker on each client:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Add the following stanza to the following file `/etc/nomad.d/client.hcl`:
```
plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}
```

This will allow containers running with the Docker drive to run privileged as this is required for CSI drivers. Additionally, volumes are enabled to allow mounting of the GCP Service Account key file that will be created next to the container.

Finally, restart the Nomad service on each client for the changes to take affect:
```bash
sudo systemctl restart nomad
```

## Setting up GCP Credentials
> **Note:** Run the following commands on the same machine you have used previously to run `gcloud` commands.

This driver requires a service account that has the following permissions and roles:
```
compute.instances.get
compute.instances.attachDisk
compute.instances.detachDisk
roles/compute.storageAdmin
roles/iam.serviceAccountUser
```

Create a designated role for the three permissions:
```bash
gcloud iam roles create nomad_the_hard_way \
  --title="Nomad the Hard Way CSI User" \
  --project="${GOOGLE_CLOUD_PROJECT}" \
  --permissions="compute.instances.get,compute.instances.attachDisk,compute.instances.detachDisk" \
  --launch-stage="GA"

NOMAD_CSI_ROLE_NAME=$(gcloud iam roles describe nomad_the_hard_way --project wlkrahdvd89pzclh9poereuzmb1axq --format="value(name)")
```

Create a dedicated service account to be used by the driver:
```bash
gcloud iam service-accounts create nomad-sa-csi

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:nomad-sa-csi@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role "roles/compute.storageAdmin"

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:nomad-sa-csi@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role "roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:nomad-sa-csi@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role "${NOMAD_CSI_ROLE_NAME}"
```

Generate a service account key for the new service account:
```bash
gcloud iam service-accounts keys create "creds.json" --iam-account "nomad-sa-csi@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" --project "${GOOGLE_CLOUD_PROJECT}"
```

Distribute the key to the clients and then delete the local copy:
```bash
for instance in nomad-client-0 nomad-client-1 nomad-client-2; do
  gcloud compute scp creds.json ${instance}:~/
done

rm creds.json
```

SSH into each client and run the following commands:
```bash
mv ~/creds.json /opt/nomad/creds.json
chmod 600 /opt/nomad/creds.json
chown nomad: /opt/nomad/creds.json
```

Now that the credentials are in place, you can install the driver.

## A Quick Note on CSI Drivers
A CSI Driver is typically has two components: a controller component and a per-node component.

The controller component can be deployed through the default [service](https://www.nomadproject.io/docs/schedulers#service) scheduler. It does not need direct node access and is responsible for responding to storage requests (ie. creating disks).

The node component should be deployed on each client in the cluster through the [system](https://www.nomadproject.io/docs/schedulers#system) scheduler. Calls are made to the CSI driver via a UNIX domain socket mounted to the Nomad task from the host. The node component needs direct access to the host for making storage available to the Nomad tasks.

For this lab, you will deploy a single job for the CSI driver running as both a controller & node. By default, this is how the GCE PD CSI driver runs and this can be supported by Nomad using a special CSI mode called `monolith`.

## Deploying the CSI Driver
Create the job file:
```bash
cat <<EOF > gce-pd-csi-plugin.nomad
job "gce-pd-csi-plugin" {
  datacenters = ["dc1"]

  type = "system"

  group "node" {
    task "node" {
      driver = "docker"

      env {
        GOOGLE_APPLICATION_CREDENTIALS = "/secrets/creds.json"
      }

      config {
        volumes = [
          "/opt/nomad/creds.json:/secrets/creds.json"
        ]

        image = "k8s.gcr.io/cloud-provider-gcp/gcp-compute-persistent-disk-csi-driver:v1.7.2"

        privileged = true

        args = [
          "-v=5",
          "-endpoint=unix:///csi/csi.sock",
          "-logtostderr",            
        ]
      }

      csi_plugin {
        id        = "gce-pd"
        type      = "monolith"
        mount_dir = "/csi"
      }
    }
  }
}
EOF
```

Register the job:
```bash
nomad job run gce-pd-csi-plugin.nomad
```

## Inspect the Storage Plugin
View information on the new plugin:
```bash
nomad plugin status
```

> output
```bash
Container Storage Interface
ID        Provider                Controllers Healthy/Expected  Nodes Healthy/Expected
gce-pd    pd.csi.storage.gke.io   1/1                           1/1
```

For a more detailed view, you can target the specific plugin:
```bash
nomad plugin status gce-pd
```

> output
```bash
ID                   = gce-pd
Provider             = pd.csi.storage.gke.io
Version              = v1.7.2
Controllers Healthy  = 1
Controllers Expected = 1
Nodes Healthy        = 1
Nodes Expected       = 1

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created     Modified
00ee74ff  ef636df1  node        6        run      running  1m50s ago  1m39s ago
```

## Create a Volume
At this time, dynamic volume provisioning is not supported in Nomad so you must create a [volume](https://www.nomadproject.io/docs/job-specification/volume) first which will create the disk in GCP.

Create the volume file:
```bash
cat <<EOF > nginx-volume.hcl
id           = "nginx" # ID as seen in nomad
name         = "nginx" # Name as seen in GCP
type         = "csi"
plugin_id    = "gce-pd" # Needs to match the deployed plugin
capacity_max = "2G"
capacity_min = "1G"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

mount_options {
  fs_type     = "xfs"
  mount_flags = ["noatime",]
}

parameters {
  replication-type = "regional-pd"
  type             = "pd-balanced"
}

topology_request {
  preferred {
    topology { 
      segments { 
        "topology.gke.io/zone" = "us-central1-a"
      }
      segments {
        "topology.gke.io/zone" = "us-central1-b"
      }
      segments {
        "topology.gke.io/zone" = "us-central1-c"
      }
    }
  }
}
EOF
```

Create the volume:
```bash
nomad volume create nginx-volume.hcl
```

> output
```bash
Created external volume projects/xxxxxxxxxxxx/zones/us-central1-a/disks/nginx with ID nginx
```

View the full details of the new volume:
```bash
ID                   = nginx
Name                 = nginx
External ID          = projects/xxxxxxxxxxxx/zones/us-central1-a/disks/nginx-gcp
Plugin ID            = gce-pd
Provider             = pd.csi.storage.gke.io
Version              = v1.7.2
Schedulable          = true
Controllers Healthy  = 1
Controllers Expected = 1
Nodes Healthy        = 1
Nodes Expected       = 1
Access Mode          = <none>
Attachment Mode      = <none>
Mount Options        = fs_type: xfs flags: [REDACTED]
Namespace            = default

Topologies
Topology  Segments
01        topology.gke.io/zone=us-central1-a

Allocations
No allocations placed
```

Validate the disk is created in GCP:
```bash
gcloud compute disks list --filter="name=('nginx')"
```

> output
```
NAME       LOCATION       LOCATION_SCOPE  SIZE_GB  TYPE         STATUS
nginx      us-central1-a  zone            1        pd-standard  READY
```

## Deploy a Stateful Application
Create a job file for the [nginx](https://nginx.org/en/) web server. This time, the NGINX's `/usr/share/nginx/html` will be persistent across jobs:
```bash
cat <<EOF > nginx-persistent.nomad
job "nginx-persistent-gce" {
  datacenters = ["dc1"]

  group "nginx-persistent-gce" {
    volume "nginx" {
        type            = "csi"
        read_only       = false
        source          = "nginx-gcp"
        attachment_mode = "file-system"
        access_mode     = "single-node-writer"
    }

    network {
      mode = "cni/bridge"
      port "http" {
        to = 80
      } 
    }
    
    service {
      name     = "nginx-persistent"
      port     = "http"
      provider = "nomad"
    }
    
    task "nginx" {
      driver = "docker"

      volume_mount {
        volume      = "nginx"
        destination = "/usr/share/nginx/html"
      }

      config {
        image = "nginx:latest"
      }
    }
  }
}
EOF
```

Register the job:
```bash
nomad job run nginx-persistent.nomad
```

Inspect the job status to ensure it is running properly:
```bash
nomad job status nginx-persistent
```

> output
```bash
ID            = nginx-persistent
Name          = nginx-persistent
Submit Date   = 2022-09-13T20:01:09Z
Type          = service
Priority      = 50
Datacenters   = dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group        Queued  Starting  Running  Failed  Complete  Lost  Unknown
nginx-persistent  0       0         1        0       0         0     0

Allocations
ID        Node ID   Task Group        Version  Desired  Status   Created     Modified
7865587f  ef636df1  nginx-persistent  0        run      running  4m40s ago   4m28s ago
```

Touch a file in the directory that is attached to the volume:
```bash
NGINX_PERSISTENT_ALLOC_ID=$(nomad service info -json nginx-persistent | jq -r '.[].AllocID')

nomad alloc exec $NGINX_PERSISTENT_ALLOC_ID /bin/bash -c 'touch /usr/share/nginx/html/index.html'
```

## Validate Data Persists
Now that you have written a file to the persistent volume, let's validate the data exists once we delete the job and re-deploy it.

Stop and remove the current NGINX job:
```bash
nomad job stop -purge nginx-persistent
```

Register the job again:
```bash
nomad job run nginx-persistent.nomad
```

Get the allocation ID and run an `ls` command to validate the file is there:
```bash
nomad alloc exec $NGINX_PERSISTENT_ALLOC_ID /bin/bash -c 'ls -l /usr/share/nginx/html/'
total 0
-rw-r--r-- 1 root root 0 Sep 14 13:31 index.html
```

Next: [Clean Up](10-clean-up.md)