#!/bin/bash

set -euo pipefail

tf_dir="$1"

printf "Terraform working directory: %s\n" "$tf_dir"

TF_IN_AUTOMATION=true terraform plan -out tfplan -input=false -detailed-exitcode
exit_code=$?

printf "Terraform exit code: %s\n" "$exit_code"
echo "##vso[task.setvariable variable=tf_detailed_exit_code;isOutput=true]$exit_code"
