#!/bin/bash

tf_dir="$1"

printf "Terraform working directory: %s\n" "$tf_dir"

TF_IN_AUTOMATION=true terraform plan -out tfplan -input=false -detailed-exitcode
exit_code=$?

printf "Terraform exit code: %s\n" "$exit_code"
echo "##vso[task.setvariable variable=tf_detailed_exit_code;isOutput=true]$exit_code"

# if exit code is equal to 2 then changes are required
# https://www.terraform.io/docs/cli/commands/plan.html#usage
if [[ $exit_code -eq 2  ]]
then
  printf "Terraform detected required changes\n"
  exit_code=0
fi

printf "Exit code: %s\n" "$exit_code"
exit "$exit_code"
