# Smoke Test
In this lab you will deploy two applications to your Nomad cluster and test connectivity to ensure the cluster functioning correctly.

## Deployments
In this section you will verify the ability to create and manage [jobs](https://www.nomadproject.io/docs/job-specification). You will also verify two containers on different nodes can communicate by constraining the jobs to two different clients.

Create a job file for the [nginx](https://nginx.org/en/) web server:
```bash
cat <<EOF > nginx.nomad
job "nginx" {
  datacenters = ["dc1"]

  constraint {
    attribute = "\${attr.unique.hostname}"
    value     = "nomad-client-0"
  }

  group "nginx" {
    network {
      mode = "cni/bridge"
      port "http" {
        to = 80
      }
    }
    
    service {
      name     = "nginx"
      port     = "http"
      provider = "nomad"
    }
    
    task "nginx" {
      driver = "containerd-driver"

      config {
        image = "nginx"
      }
    }
  }
}
EOF
```

Register the job:
```bash
nomad job run nginx.nomad
```

Get allocation ID:
```bash
NGINX_ALLOC_ID=$(nomad service info -json nginx | jq -r '.[].AllocID')
```

Create a job file for [toolbox](https://github.com/jacobmammoliti/toolbox):
```bash
cat <<EOF > toolbox.nomad
job "toolbox" {
  datacenters = ["dc1"]

  constraint {
    attribute = "\${attr.unique.hostname}"
    value     = "nomad-client-1"
  }

  group "toolbox" {
    network {
      mode = "cni/bridge"
    }
    
    service {
      name     = "toolbox"
      provider = "nomad"
    }
    
    task "toolbox" {
      driver = "containerd-driver"

      config {
        image = "jacobmammoliti/toolbox"
      }

      template {
        data = <<EOH
echo "|------------------------------------|"
echo "| Making an HTTP request to nginx... |"
echo "|------------------------------------|"
sleep 3
{{ range nomadService "nginx" }}
curl -I "http://{{ .Address }}:{{ .Port }}"
{{ end }}
        EOH

        destination = "local/check-connectivity"
      }
    }
  }
}
EOF
```

Register the job:
```bash
nomad job run toolbox.nomad
```

Get allocation ID:
```bash
TOOLBOX_ALLOC_ID=$(nomad service info -json toolbox | jq -r '.[].AllocID')
```

### Logs
In this section you will be able to [retrieve job logs](https://www.nomadproject.io/docs/commands/alloc/logs).

Print the `nginx` job logs:
```bash
nomad alloc logs $NGINX_ALLOC_ID
```

### Exec and Validate Communications
In this section you will verify the ability to execute commands in a container and validate two containers can talk to each other from different nodes.

```bash
nomad alloc exec $TOOLBOX_ALLOC_ID /bin/sh
```

Make an HTTP request to the NGINX job:
```bash
sh local/check-connectivity
```

> output
```bash
|------------------------------------|
| Making an HTTP request to nginx... |
|------------------------------------|
HTTP/1.1 200 OK
Server: nginx/1.21.6
Date: Sat, 21 May 2022 16:50:46 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 25 Jan 2022 15:03:52 GMT
Connection: keep-alive
ETag: "61f01158-267"
Accept-Ranges: bytes
```

Exit the container when done:
```bash
exit
```

## Service Discovery
Nomad 1.3 brought native service discovery. Services can be registered to Nomad via the `service` [stanza](https://www.nomadproject.io/docs/job-specification/service#provider) in the Job template.

To discover a service in a Job, use the `nomadService` keyword in your template stanza as done in the `toolbox` job above.

View all services registered to Nomad:
```bash
nomad service list
```

> output
```bash
Service Name  Tags
nginx         []
toolbox       []
```

View a specific service:
```bash
nomad service info nginx
```

> output
```bash
Job ID  Address            Tags  Node ID   Alloc ID
nginx   10.240.0.20:27367  []    7869771c  b2c794f5
```

## Interact with Containerd Directly
If you are interested in interacting with Containerd directly, you can run the following commands on any of the client nodes. Containerd has the concept of namespaces and all images and containers are deployed in the `nomad` namespace.

View container images:
```bash
sudo ctr --namespace nomad images ls
```

View running containers on the node:
```bash
sudo ctr --namespace nomad containers ls
```

View running tasks:
```bash
sudo ctr --namespace nomad task ls
```

Kill running task:
```bash
sudo ctr --namespace nomad task kill <TASK_NAME>
```

Delete a container:
```bash
sudo ctr --namespace nomad containers del <CONTAINER_NAME>
```

Next: [Adding Persistent Storage](09-persistent-storage.md)