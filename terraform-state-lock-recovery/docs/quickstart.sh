#!/usr/bin/env bash
set -euo pipefail

echo "==> Moving into infra/"
cd "$(dirname "$0")/../infra"

echo "==> Init (reconfigure backend if needed)"
terraform init -reconfigure

echo "==> Plan"
terraform plan -out tfplan

echo "==> Apply"
terraform apply tfplan
