#!/bin/bash

# shellcheck source=./scripts/functions.sh
# shellcheck disable=SC1091
source ./scripts/functions.sh

#functions

install_teraform() {

  local tf_version="$1"

  wget --quiet "https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"
  unzip "terraform_${tf_version}_linux_amd64.zip"
  rm "terraform_${tf_version}_linux_amd64.zip"
  sudo mv terraform /usr/bin

}

# end functions


tf_require_version=$1

if [[ "$tf_require_version" == "latest" ]]
then
  rest_api_call "GET" "https://checkpoint-api.hashicorp.com/v1/check/terraform"
  tf_require_version=$(echo "$out" | jq -r '.current_version')
fi

echo "Checking if terraform is installed"
check_command "terraform"
if [[ ${cmd_installed} -eq 0 ]]
then
  echo "Terraform not currently installed, installing "
  install_teraform "$tf_require_version"
else
  echo "Terraform already installed"
fi


tf_version=$(terraform version -json | jq -r '.terraform_version')

printf "Currently installed Terraform version: %s\n"  "$tf_version"

if [[ "$tf_version" == "tf_require_version" ]]
then
  echo "Currently installed Terraform satisfies requirements"
else
  echo "Currently installed Terraform does not satisfy requirements, installing "
  install_teraform "$tf_require_version"
fi

terraform version
