#!/usr/bin/env bash
set -euo pipefail

NS="ops"
APP="crash-demo"

echo "==> Create namespace (if not exists)"
kubectl get ns "${NS}" >/dev/null 2>&1 || kubectl create ns "${NS}"

echo "==> Apply broken deployment + service"
kubectl apply -n "${NS}" -f k8s/deployment-broken.yaml
kubectl apply -n "${NS}" -f k8s/service.yaml

echo "==> Watch pods (Ctrl+C when you see CrashLoopBackOff)"
kubectl get pods -n "${NS}" -w || true

echo "==> Get latest pod name"
POD="$(kubectl get pods -n "${NS}" -l app=${APP} -o jsonpath='{.items[0].metadata.name}')"
echo "POD=${POD}"

echo "==> Logs (current)"
kubectl logs -n "${NS}" "${POD}" || true

echo "==> Logs (previous) - best clue"
kubectl logs -n "${NS}" "${POD}" --previous || true

echo "==> Describe pod (events + exit code)"
kubectl describe pod -n "${NS}" "${POD}" | sed -n '1,200p'

echo "==> Apply fix (APP_MODE added)"
kubectl apply -n "${NS}" -f k8s/deployment-fixed.yaml

echo "==> Rollout status"
kubectl rollout status deployment/${APP} -n "${NS}"

echo "==> Pods after fix"
kubectl get pods -n "${NS}" -o wide

echo "==> Service info"
kubectl get svc -n "${NS}"

echo ""
echo "Done. If you want browser proof:"
echo "  kubectl port-forward -n ${NS} svc/${APP} 8080:80"
echo "Then open: http://localhost:8080"
