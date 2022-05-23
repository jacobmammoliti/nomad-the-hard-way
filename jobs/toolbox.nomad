job "toolbox" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.unique.hostname}"
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