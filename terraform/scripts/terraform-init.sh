#!/bin/bash

set -euo pipefail

tf_dir="$1"

printf "Terraform working directory: %s\n" "$tf_dir"

# install git if not already installedgit status
git --version || apt install git

terraform init
