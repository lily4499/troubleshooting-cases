#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f manifests/03-deploy-fix.yaml

echo ""
echo "Watch rollout:"
echo "  kubectl -n ops-demo rollout status deploy/web"
echo ""
echo "Verify:"
echo "  kubectl -n ops-demo get pods -o wide"
echo "  kubectl -n ops-demo get endpoints web"
echo ""
echo "Optional browser proof:"
echo "  kubectl -n ops-demo port-forward svc/web 8080:80"
echo "  open http://localhost:8080"
