# Prerequisites
## Google Cloud Platform
This tutorial will use [Google Cloud Platform](https://cloud.google.com/gcp) for the compute and network infrastructure required to bootstrap a Nomad cluster.

[Estimated Cost](https://cloud.google.com/products/calculator#id=0fa0ba73-1475-4eaa-b727-3020feaf871c) to run this tutorial: $11.40 per day.

> The compute resources required for this tutorial exceed the Google Cloud Platform free tier.

## Google Cloud Platform SDK
### Install the SDK
You can follow the instructions to install the SDK [here](https://cloud.google.com/sdk/docs/install-sdk).

### Set Defaults
Throughout this tutorial, the `gcloud` command will be used where it is assumed the project, region, and zone have been pre-set.

If you are using the `gcloud` command for the first time, initialize and authenticate to GCP:
```bash
gcloud init

gcloud auth login
```

Set the default region and zone:
```bash
gcloud config set compute/region us-central1

gcloud config set compute/zone us-central1-a
```

Set the Project ID (ID, not name) as an environment variable:
```bash
export GOOGLE_CLOUD_PROJECT=<YOUR PROJECT ID HERE>
```

> You can use `gcloud compute zone list` to view additional regions and zones.

Next: [Installing the Client Tools](02-client-tools.md)