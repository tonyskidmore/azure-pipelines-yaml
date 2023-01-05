#!/bin/bash

tf_dir="$1"
tf_destroy="$2"

printf "Terraform working directory: %s\n" "$tf_dir"

printf "tf_destroy: %s\n" "$tf_destroy"

if jq -r 'has("planCommandOptions")' <<< "${ENV_PARAMS}" | grep -q "true"
then
  plan_params=$(jq -r '.planCommandOptions' <<< "${ENV_PARAMS}")
  printf "planCommandOptions: %s\n" "$plan_params"
else
  echo "No planCommandOptions environment parameters found"
fi

if [[ "${tf_destroy,,}" == "true" ]]
then
  echo "Destroy mode requested"
  std_params=("plan" "-destroy" "-input=false" "-out=tfplan")
else
  echo "Apply mode requested"
  std_params=("plan" "-out=tfplan" "-input=false" "-detailed-exitcode")
fi

if [[ -n "$plan_params" ]]
then
  OLDIFS="$IFS"
  IFS=' ' read -ra cmd_opts <<< "$plan_params"
  params=( "${std_params[@]}" "${cmd_opts[@]}" )
  IFS="$OLDIFS"
else
  params=( "${std_params[@]}" )
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
