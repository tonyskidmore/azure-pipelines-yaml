#!/bin/bash

set -euo pipefail

env

tf_dir="$1"
tf_destroy_mode="$2"
tf_destroy_local="$3"

printf "Terraform working directory: %s\n" "$tf_dir"
printf "Terraform destroy mode: %s\n" "$tf_destroy_mode"
printf "Terraform local destroy: %s\n" "$tf_destroy_local"

# install git if not already installedgit status
git --version || apt install git

if [[ -n "$STATE_STORAGE_ACCOUNT_NAME" && -n "$STATE_CONTAINER_NAME" && -n "$STATE_KEY" && -n "$STATE_RESOURCE_GROUP_NAME" ]]
then
  std_params=("init" "-backend-config=storage_account_name=$STATE_STORAGE_ACCOUNT_NAME" \
              "-backend-config=container_name=$STATE_CONTAINER_NAME" \
              "-backend-config=key=$STATE_KEY" \
              "-backend-config=resource_group_name=$STATE_RESOURCE_GROUP_NAME")
else
  std_params=("init")
fi

if [[ -n "$STATE_SUBSCRIPTION_ID" ]]
then
  cmd_opts=( "-backend-config=subscription_id=$STATE_SUBSCRIPTION_ID" )
  params=( "${std_params[@]}" "${cmd_opts[@]}" )
else
  params=( "${std_params[@]}" )
fi

if [[ "${tf_destroy_mode,,}" == "true" ]] && [[ "${tf_destroy_local,,}" == "true" ]]
then
  echo "Local init requested"
  ls -alt
  rm backend.tf
  ls -alt
  TF_IN_AUTOMATION=true terraform init -migrate-state -force-copy
else
  printf "terraform %s\n" "${params[*]}"
  TF_IN_AUTOMATION=true terraform "${params[@]}"
fi
