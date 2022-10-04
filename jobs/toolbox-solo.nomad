job "toolbox" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "nomad-client-0"
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
        image = "jacobmammoliti/toolbox:latest"
      }
    }
  }
}