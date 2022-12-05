#!/bin/bash

set -euo pipefail

tf_dir="$1"
tf_destroy_mode="$2"
tf_destroy_local="$3"

printf "Terraform working directory: %s\n" "$tf_dir"
printf "Terraform destroy mode: %s\n" "$tf_destroy_mode"
printf "Terraform local destroy: %s\n" "$tf_destroy_local"

# install git if not already installedgit status
git --version || apt install git

echo "Running terraform init"
TF_IN_AUTOMATION=true terraform init

if [[ "${tf_destroy_mode,,}" == "true" ]] && [[ "${tf_destroy_local,,}" == "true" ]]
then
  echo "Local init requested"
  ls -alt
  rm backend.tf
  ls -alt
  TF_IN_AUTOMATION=true terraform init -migrate-state -force-copy
fi
