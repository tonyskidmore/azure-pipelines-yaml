#!/bin/bash

set -euo pipefail

# functions

check_command () {
  # Determine if command is installed
  cmd_bin=$(command -v "${1}" 2>/dev/null)
  printf "${1} path: %s\n" "${cmd_bin:-Not found}"
  if [[ -z "${cmd_bin}" ]]
  then
    cmd_installed=1
  else
    cmd_installed=0
  fi
}

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

check_command "terraform"
if [[ ${cmd_installed} -eq 0 ]]
then
  echo "Terraform not currently installed, installing "
  install_teraform "$tf_require_version"
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
