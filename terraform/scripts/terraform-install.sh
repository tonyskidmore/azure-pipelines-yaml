#!/bin/bash

set -euo pipefail
SYSTEM_DEFAULTWORKINGDIRECTORY=${SYSTEM_DEFAULTWORKINGDIRECTORY:-}

# functions

build_params() {

  local method="$1"
  local url="$2"

  HTTP_RETRIES=${HTTP_RETRIES:-10}
  HTTP_RETRY_DELAY=${HTTP_RETRY_DELAY:-3}
  HTTP_RETRIES_MAX_TIME=${HTTP_RETRIES_MAX_TIME:-120}
  HTTP_MAX_TIME=${HTTP_MAX_TIME:-120}
  HTTP_CONNECT_TIMEOUT=${HTTP_CONNECT_TIMEOUT:-20}

  params=(
          "--silent" \
          "--show-error" \
          "--retry" "$HTTP_RETRIES" \
          "--retry-delay" "$HTTP_RETRY_DELAY" \
          "--retry-max-time" "$HTTP_RETRIES_MAX_TIME" \
          "--max-time" "$HTTP_MAX_TIME" \
          "--connect-timeout" "$HTTP_CONNECT_TIMEOUT" \
          "--write-out" "\n%{http_code}" \
          "--header" "Content-Type: application/json" \
          "--request" "$method" \
          "$url"
  )

}

rest_api_call() {

  exit_code=0

  if [ "$#" -ne 2 ]
  then
      printf "Expected 2 function arguments, got %s\n" "$#"
      exit 1
  fi

  method="$1"
  url="$2"


  if [[ "$method" == "GET" ]]
  then
    printf "method: %s\n" "$method"
  else
    printf "Expected method to be one of: GET got %s\n" "$method"
    exit 1
  fi

  build_params "$method" "$url"

  # printf "curl %s\n" "${params[*]}"
  res=$(curl "${params[@]}")
  exit_code=$?

  # https://unix.stackexchange.com/questions/572424/retrieve-both-http-status-code-and-content-from-curl-in-a-shell-script
  http_code=$(tail -n1 <<< "$res") # get the last line
  out=$(sed '$ d' <<< "$res") # get all but the last line which contains the status code

  printf "http_code: %s\n" "$http_code"
  printf "out: %s\n" "$out"
  printf "exit_code: %s\n" "$exit_code"

}

install_teraform() {

  local tf_version="$1"



  tf_zip_filename="terraform_${tf_version}_linux_amd64.zip"
  tf_checksum_filename="terraform_${tf_version}_SHA256SUMS"
  tf_download_url="https://releases.hashicorp.com/terraform/${tf_version}/${tf_zip_filename}"
  tf_checksum_url="https://releases.hashicorp.com/terraform/${tf_version}/${tf_checksum_filename}"

  rm -f "$tf_zip_filename"

  printf "Downloading Terraform from: %s\n" "$tf_download_url"
  wget "$tf_download_url" -O "$tf_zip_filename" --tries=5 --waitretry=3
  printf "Downloading Terraform checksums from: %s\n" "$tf_checksum_url"
  wget "$tf_checksum_url" -O "$tf_checksum_filename" --tries=5 --waitretry=3

  echo "Validating downloaded file checksum"
  sha256sum --ignore-missing -c "$tf_checksum_filename"

  echo "View file $tf_zip_filename"
  file "$tf_zip_filename"

  echo "Unzip test $tf_zip_filename"
  unzip -t "$tf_zip_filename"

  printf "Working directory: %s\n" "$PWD"
  printf "Extracting: %s\n" "$tf_zip_filename"
  unzip "${PWD}/${tf_zip_filename}"

  # TODO: remove
  ls -al

  if [[ -n "$SYSTEM_DEFAULTWORKINGDIRECTORY" ]]
  then
    printf "Copying %s to %s\n" "$tf_zip_filename" "$SYSTEM_DEFAULTWORKINGDIRECTORY"
    sudo cp terraform "$SYSTEM_DEFAULTWORKINGDIRECTORY"
  fi

  tf_dest="/usr/local/bin"
  printf "Moving terraform to %s\n" "$tf_dest"
  sudo mv terraform "$tf_dest"

  rm -f "$tf_zip_filename"
  rm -f "$tf_checksum_filename"

}

# end functions


tf_require_version=$1

if [[ "$tf_require_version" == "latest" ]]
then
  rest_api_call "GET" "https://checkpoint-api.hashicorp.com/v1/check/terraform"
  tf_latest_version=$(echo "$out" | jq -r '.current_version')
  tf_install_version="$tf_latest_version"
else
  tf_install_version="$tf_require_version"
fi

echo "Checking if terraform is installed"
# check_command "terraform"
if ! command -v terraform
then
  echo "Terraform not currently installed, installing "
  install_teraform "$tf_install_version"
else
  echo "Terraform already installed"
fi


tf_version=$(terraform version -json | jq -r '.terraform_version')

printf "Currently installed Terraform version: %s\n"  "$tf_version"
printf "Required Terraform version: %s\n"  "$tf_require_version"
printf "Terraform version to install: %s\n"  "$tf_install_version"

if [[ "$tf_version" == "$tf_install_version" ]] || [[ "$tf_require_version" == "latest" && "$tf_version" == "$tf_latest_version" ]]
then
  echo "Currently installed Terraform satisfies requirements"
else
  echo "Currently installed Terraform does not satisfy requirements, installing "
  install_teraform "$tf_install_version"
fi

terraform version -json
