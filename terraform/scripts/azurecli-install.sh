#!/bin/bash

AZURE_CLI_VERSION=${AZURE_CLI_VERSION:-2.42.0}

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# shellcheck source=/dev/null
source /etc/os-release
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y "azure-cli=${AZURE_CLI_VERSION}-1~focal"
