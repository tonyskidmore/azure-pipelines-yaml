#!/bin/bash

set -euo pipefail

tf_dir="$1"

printf "Terraform working directory: %s\n" "$tf_dir"

TF_IN_AUTOMATION=true terraform plan -out tfplan
