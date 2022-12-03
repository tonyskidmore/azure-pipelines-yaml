#!/bin/bash

set -e

if [[ -n "$AZ_SUBSCRIPTION" ]]
then
  printf "azureSubscription: %s\n" "$AZ_SUBSCRIPTION"
  subscription_id="$AZ_SUBSCRIPTION"
else
  subscription_id=$(az account show --query 'id' --output tsv)
fi

tenant_id=$(az account show --query 'tenantId' --output tsv)
client_id=${servicePrincipalId:-}
client_secret=${servicePrincipalKey:-}
echo "##vso[task.setvariable variable=ARM_SUBSCRIPTION_ID;]$subscription_id"
echo "##vso[task.setvariable variable=ARM_TENANT_ID;]$tenant_id"
echo "##vso[task.setvariable variable=ARM_CLIENT_ID;]$client_id"
echo "##vso[task.setvariable variable=ARM_CLIENT_SECRET;]$client_secret"
