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