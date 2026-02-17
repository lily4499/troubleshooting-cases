#!/usr/bin/env bash
set -euo pipefail

kubectl delete ns ops-demo --ignore-not-found=true
