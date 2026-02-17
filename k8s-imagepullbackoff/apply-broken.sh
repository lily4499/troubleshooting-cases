#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-deploy-broken.yaml
kubectl apply -f manifests/02-service.yaml

echo ""
echo "Now run:"
echo "  kubectl -n ops-demo get pods"
echo "  kubectl -n ops-demo describe pod <pod-name>"
echo "  kubectl -n ops-demo get events --sort-by=.lastTimestamp | tail -n 30"
