# Installing the Client Tools
In this lab you will install the command line utilities required throughout the tutorial: [nomad](https://releases.hashicorp.com/nomad/), [cfssl](https://github.com/cloudflare/cfssl), and [jq](https://github.com/stedolan/jq)

## Install jq
The `jq` tool is used to process JSON data retrieved from the Nomad API.

```bash
export JQ_VERSION=1.6
```

### MacOS
```bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-"$JQ_VERSION"/jq-osx-amd64
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
wget -O jq https://github.com/stedolan/jq/releases/download/jq-"$JQ_VERSION"/jq-linux64
```

```bash
sudo mv jq /usr/local/bin
```

```bash
sudo chmod u+x /usr/local/bin/jq
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

## Install Nomad
The `nomad` command line utility is used to interact with your Nomad servers. Download and install `nomad` from the official HashiCorp releases page:

```bash
export NOMAD_VERSION=$(curl -L -s https://api.releases.hashicorp.com/v1/releases/nomad | jq -r '.[0]'.version)
```

### MacOS
```bash
wget https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/nomad_"$NOMAD_VERSION"_darwin_amd64.zip
```

```bash
unzip nomad_"$NOMAD_VERSION"_darwin_amd64.zip
```

```bash
sudo mv nomad /usr/local/bin
```

```bash
rm nomad_"$NOMAD_VERSION"_darwin_amd64.zip
```

Can also install with Homebrew:
```bash
brew install nomad
```

### Linux
```bash
wget https://releases.hashicorp.com/nomad/"$NOMAD_VERSION"/nomad_"$NOMAD_VERSION"_linux_amd64.zip
```

```bash
unzip nomad_"$NOMAD_VERSION"_linux_amd64.zip
```

```bash
sudo mv nomad /usr/local/bin
```

```bash
rm nomad_"$NOMAD_VERSION"_linux_amd64.zip
```

### Verification
Verify the version:
```bash
nomad version
```
> output
```
Nomad v1.3.5
```

## Install cfssl
The `cfssl` and `cfssljson` tools are used to provision a PKI infratructure and generate TLS certificates.

```bash
export CFSSL_VERSION=1.6.2
```

### MacOS
```bash
wget -O cfssl https://github.com/cloudflare/cfssl/releases/download/v"$CFSSL_VERSION"/cfssl_"$CFSSL_VERSION"_darwin_amd64
wget -O cfssljson https://github.com/cloudflare/cfssl/releases/download/v"$CFSSL_VERSION"/cfssljson_"$CFSSL_VERSION"_darwin_amd64
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
wget -O cfssl https://github.com/cloudflare/cfssl/releases/download/v"$CFSSL_VERSION"/cfssl_"$CFSSL_VERSION"_linux_amd64
wget -O cfssljson https://github.com/cloudflare/cfssl/releases/download/v"$CFSSL_VERSION"/cfssljson_"$CFSSL_VERSION"_linux_amd64
```

```bash
sudo mv cfssl /usr/local/bin
sudo mv cfssljson /usr/local/bin
```

```bash
sudo chmod u+x /usr/local/bin/cfssl
sudo chmod u+x /usr/local/bin/cfssljson
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

Next: [Provisioning Compute Resources](03-compute-resources.md)