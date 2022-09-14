job "nfs-csi-plugin-controller" {
  datacenters = ["dc1"]

  group "controller" {
    task "controller" {
      driver = "docker"

      config {
        image      = "registry.k8s.io/sig-storage/nfsplugin:v4.1.0"
        privileged = true

        host_network = true
        
        args = [
          "-v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
        ]
      }

      csi_plugin {
        id        = "nfs"
        type      = "controller"
        mount_dir = "/csi"
      }
    }
  }
}