# Provisioning Network Routes
Container jobs scheduled to a node recieve an IP address from the node's CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/vpc/docs/routes).

In this lab you will create a route for each client node that maps the node's CIDR range to the node's internal IP address.

## The Routing Tables
In this section you will gather the information required to create routes in the `nomad-the-hard-way` VPC network.

Print the internal IP address and CIDR range for each client instance:
```bash
for instance in nomad-client-0 nomad-client-1 nomad-client-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done
```

> output
```bash
10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
```

## Routes
Create network routes for each client instance:
```bash
for i in 0 1 2; do
  gcloud compute routes create nomad-route-10-200-${i}-0-24 \
    --network nomad-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

List the routes in the `nomad-the-hard-way` VPC network:
```bash
gcloud compute routes list --filter "network: nomad-the-hard-way"
```

> output
```bash
NAME                            NETWORK             DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-405fc9813d6ff2a2  nomad-the-hard-way  10.240.0.0/24  nomad-the-hard-way        0
default-route-a5e4150438aa957f  nomad-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
nomad-route-10-200-0-0-24       nomad-the-hard-way  10.200.0.0/24  10.240.0.20               1000
nomad-route-10-200-1-0-24       nomad-the-hard-way  10.200.1.0/24  10.240.0.21               1000
nomad-route-10-200-2-0-24       nomad-the-hard-way  10.200.2.0/24  10.240.0.22               1000
```

Next: [Smoke Test](08-smoke-test.md)