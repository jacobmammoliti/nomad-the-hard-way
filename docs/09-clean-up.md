# Clean Up
In this final lab, you will delete all the resources created in GCP from this tutorial.

## Compute Instances
Delete all Nomad Servers and Clients:
```bash
gcloud --quiet compute instances delete \
  nomad-server-0 nomad-server-1 nomad-server-2 \
  nomad-client-0 nomad-client-1 nomad-client-2 \
  --zone $(gcloud config get-value compute/zone)
```

## Service Account
Delete the service account:
```bash
gcloud projects remove-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:nomad-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role "roles/compute.viewer"

gcloud --quiet iam service-accounts delete nomad-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

## Networking
### Load Balancer
Delete the external load balancer resources:
```bash
gcloud --quiet compute forwarding-rules delete nomad-forwarding-rule \
  --region $(gcloud config get-value compute/region)

gcloud --quiet compute target-pools delete nomad-target-pool

gcloud --quiet compute addresses delete nomad-the-hard-way
```

### Firewall rules
Delete the `nomad-the-hard-way` firewall rules:
```bash
gcloud --quiet compute firewall-rules delete \
  nomad-the-hard-way-allow-internal \
  nomad-the-hard-way-allow-external
```

### VPC
Delete the `nomad-the-hard-way` VPC:
```bash
gcloud --quiet compute routes delete \
  nomad-route-10-200-0-0-24 \
  nomad-route-10-200-1-0-24 \
  nomad-route-10-200-2-0-24

gcloud --quiet compute networks subnets delete nomad

gcloud --quiet compute networks delete nomad-the-hard-way
```