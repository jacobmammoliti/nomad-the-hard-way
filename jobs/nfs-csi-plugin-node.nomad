job "nfs-csi-plugin-node" {
  datacenters = ["dc1"]
  type        = "system"

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image        = "registry.k8s.io/sig-storage/nfsplugin:v4.1.0"
        privileged   = true
        host_network = true

        args = [
          "-v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
        ]
      }

      csi_plugin {
        id        = "nfs"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}