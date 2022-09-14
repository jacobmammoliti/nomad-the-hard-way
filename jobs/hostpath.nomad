job "csi-plugin" {
  datacenters = ["dc1"]

  group "csi" {
    task "plugin" {
      driver = "containerd-driver"

      config {
        image = "k8s.gcr.io/sig-storage/hostpathplugin:v1.9.0"

        args = [
          "--drivername=csi-hostpath",
          "--v=5",
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=foo",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "hostpath-plugin0"
        type      = "monolith"
        mount_dir = "/csi"
      }
    }
  }
}