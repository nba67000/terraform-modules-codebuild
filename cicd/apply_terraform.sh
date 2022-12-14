#!/bin/bash

# fail on any error
set -eu

# go to the main folder to use terraform commands
cd ..
cd jupiter-website-ecs

# initialize terraform
terraform init

# # apply terraform
terraform apply -auto-approve

# destroy terraform
# terraform destroy -auto-approve