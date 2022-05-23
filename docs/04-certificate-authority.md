# Provisioning a CA and Generating TLS Certificates and a Gossip Key
In this lab you will provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) using CloudFlare's PKI toolkit, [cfssl](https://github.com/cloudflare/cfssl), then use it to bootstrap a Certificate Authority, and generate TLS certificates for the nodes.

## Certificate Authority
In this section you will provision a Certificate Authority that can be used to generate additional TLS certificates.

Generate the CA configuration file, certificate, and private key:
```bash
cat <<EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "nomad": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat <<EOF > ca-csr.json
{
  "CN": "Nomad",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CA",
      "L": "Toronto",
      "O": "Nomad",
      "OU": "CA",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

Results:
```bash
ca-key.pem
ca.pem
```

## Node Certificates
In this section you will generate the node certificates for both servers and clients.
```bash
cat <<EOF > server-csr.json
{
    "hosts": [
      "server.global.nomad",
      "localhost",
      "127.0.0.1",
      "${NOMAD_PUBLIC_ADDRESS}"
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CA",
        "L": "Toronto",
        "O": "Nomad",
        "OU": "CA",
        "ST": "Ontario"
      }
    ]
}
EOF

cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server

cat <<EOF > client-csr.json
{
    "hosts": [
      "client.global.nomad",
      "localhost",
      "127.0.0.1"
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CA",
        "L": "Toronto",
        "O": "Nomad",
        "OU": "CA",
        "ST": "Ontario"
      }
    ]
}
EOF

cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
```

Results:
```bash
server-key.pem
server.pem
client-key.pem
client.pem
```

## Distribute the Server and Client Certificates
Copy the appropriate certificates and private keys to each server instance:
```bash
for instance in nomad-server-0 nomad-server-1 nomad-server-2; do
  gcloud compute scp ca.pem server-key.pem server.pem ${instance}:~/
done
```

Copy the appropriate certificates and private keys to each client instance:
```bash
for instance in nomad-client-0 nomad-client-1 nomad-client-2; do
  gcloud compute scp ca.pem client-key.pem client.pem ${instance}:~/
done
```

### Generate a Gossip Encryption Key
Generate a Gossip encryption key to encrypt all gossip communication between servers:

> **Note:** Make note of this key as you will use it when writing the Nomad Server config in the next section.

```bash
nomad operator keygen
```
> output
```bash
jFTLMDV9y6hPiVodamItlaOjMOQAE/6cUiiV4d2JLWg=
```

Next: [Bootstrapping the Nomad Servers](05-bootstrapping-nomad-servers.md)