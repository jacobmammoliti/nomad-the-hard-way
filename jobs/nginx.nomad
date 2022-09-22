job "nginx" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.unique.hostname}"
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
        image = "nginx:latest"
      }
    }
  }
}