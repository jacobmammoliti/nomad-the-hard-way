job "gce-pd-csi-plugin" {
  datacenters = ["dc1"]
  type        = "system"

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