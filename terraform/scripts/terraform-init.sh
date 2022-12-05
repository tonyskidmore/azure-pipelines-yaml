#!/bin/bash

set -euo pipefail

tf_dir="$1"
tf_destroy_local="$2"

printf "Terraform working directory: %s\n" "$tf_dir"

# install git if not already installedgit status
git --version || apt install git

if [[ "${tf_destroy_local,,}" == "true" ]]
then
  rm "$tf_dir/backend.tf"
  TF_IN_AUTOMATION=true terraform init -migrate-state -force-copy
else
  TF_IN_AUTOMATION=true terraform init
fi
