# Installing the Client Tools
In this lab you will install the command line utilities required throughout the tutorial: [nomad](https://releases.hashicorp.com/nomad/), [cfssl](https://github.com/cloudflare/cfssl), and [jq](https://github.com/stedolan/jq)

## Install Nomad
The `nomad` command line utility is used to interact with your Nomad servers. Download and install `nomad` from the official HashiCorp releases page:

### MacOS
```bash
wget -O nomad https://releases.hashicorp.com/nomad/1.3.0/nomad_1.3.0_darwin_arm64.zip
```

```bash
unzip nomad_1.3.0_darwin_arm64.zip
```

```bash
sudo mv nomad /usr/local/bin
```

Can also install with Homebrew:
```bash
brew install nomad
```

### Linux
```bash
wget -O nomad https://releases.hashicorp.com/nomad/1.3.0/nomad_1.3.0_linux_amd64.zip
```

```bash
unzip nomad_1.3.0_linux_amd64.zip
```

```bash
sudo mv nomad /usr/local/bin
```

### Verification
Verify the version:
```bash
nomad version
```
> output
```
Nomad v1.3.0
```

## Install cfssl
The `cfssl` and `cfssljson` tools are used to provision a PKI infratructure and generate TLS certificates.

### MacOS
```bash
wget -O cfssl https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_darwin_amd64
wget -O cfssljson https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_darwin_amd64
```

```bash
sudo mv cfssl /usr/local/cfssl
sudo mv cfssljson /usr/local/cfssljson
```

Can also install with Homebrew:
```bash
brew instal cfssl
```

### Linux
```bash
wget -O cfssl https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64
wget -O cfssljson https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64
```

```bash
sudo mv cfssl /usr/local/cfssl
sudo mv cfssljson /usr/local/cfssljson
```

### Verification:
Verify the version of `cfssl` and `cfssljson`:
```bash
cfssl version
```
> output
```bash
Version: 1.6.1
Runtime: go1.17.2
```

```bash
cfssljson -version
```
> output
```bash
Version: 1.6.1
Runtime: go1.17.2
```

## Install jq
The `jq` tool is used to process JSON data retrieved from the Nomad API.

### MacOS
```bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
```

```bash
sudo mv jq /usr/local/jq
```

Can also install with Homebrew:
```bash
brew instal jq
```

### Linux
```bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
```

```bash
sudo mv jq /usr/local/jq
```

### Verification
Verify the version:
```bash
jq --help
```
> output
```
jq - commandline JSON processor [version 1.6]
...
```

Next: [Provisioning Compute Resources](03-compute-resources.md)