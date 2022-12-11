#!/bin/bash

set -e

tf_dir="$1"
tf_destroy="$2"

printf "Terraform working directory: %s\n" "$tf_dir"

printf "tf_destroy: %s\n" "$tf_destroy"

# params=("plan" "-out=tfplan" "-input=false" "-detailed-exitcode")

if [[ "${tf_destroy,,}" == "true" ]]
then
  echo "Destroy mode requested"
  params=("plan" "-destroy" "-input=false" "-out=tfplan")
else
    echo "Apply mode requested"
  params=("plan" "-out=tfplan" "-input=false" "-detailed-exitcode")
fi

printf "terraform %s\n" "${params[*]}"
TF_IN_AUTOMATION=true terraform "${params[@]}"
exit_code=$?

printf "Terraform exit code: %s\n" "$exit_code"
echo "##vso[task.setvariable variable=tf_detailed_exit_code;isOutput=true]$exit_code"

# if exit code is equal to 2 then changes are required
# https://www.terraform.io/docs/cli/commands/plan.html#usage
if [[ $exit_code -eq 2 ]] || [[ "${tf_destroy,,}" == "true" ]]
then
  printf "Terraform detected required changes\n"
  echo "##vso[task.setvariable variable=TF_REQUIRED_CHANGES;]true"
  exit_code=0
fi

printf "Exit code: %s\n" "$exit_code"
exit "$exit_code"
