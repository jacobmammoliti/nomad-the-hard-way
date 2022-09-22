job "nginx-persistent-gce" {
  datacenters = ["dc1"]

  group "nginx-persistent-gce" {
    volume "nginx" {
      type            = "csi"
      read_only       = false
      source          = "nginx"
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