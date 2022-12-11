#!/bin/bash

# set -euo pipefail

tf_dir="$1"
tf_destroy_mode="$2"
tf_destroy_local="$3"

echo "Environment Parameters"
echo "$ENV_PARAMS"
# echo "$ENV_PARAMS" | jq

if jq -r 'has("beKey")' <<< "${ENV_PARAMS}" | grep -q "true"
then
  # declare a bash associative array
  declare -A env_params

  # loop through the list of maps and create key/value pairs using to_entries to add the entries to associative array
  while IFS="=" read -r key value; do
    env_params["$key"]="$value"
  done < <(jq -r '. | to_entries | .[] | .key + "=" + .value' <<< "${ENV_PARAMS}")

  # loop through the array and variables key=value
  for key in "${!env_params[@]}"; do
    export "$key"="${env_params[$key]}"
  done

else
  echo "No backend environment parameters found"
fi

env

printf "Terraform working directory: %s\n" "$tf_dir"
printf "Terraform destroy mode: %s\n" "$tf_destroy_mode"
printf "Terraform local destroy: %s\n" "$tf_destroy_local"

# install git if not already installedgit status
git --version || apt install git

if [[ -n "$beStorageAccountName" && -n "$beContainerName" && -n "$beKey" && -n "$beResourceGroupName" ]]
then
  std_params=("init" "-backend-config=storage_account_name=$beStorageAccountName" \
              "-backend-config=container_name=$beContainerName" \
              "-backend-config=key=$beKey" \
              "-backend-config=resource_group_name=$beResourceGroupName")
else
  std_params=("init")
fi

if [[ -n "$beSubscriptionId" ]]
then
  cmd_opts=( "-backend-config=subscription_id=$beSubscriptionId" )
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
