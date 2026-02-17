
# Troubleshooting (Real “Ops” Scenarios)

This folder is my **hands-on troubleshooting portfolio**.  
Each subfolder is a real-world incident style lab where I prove I can troubleshoot like an on-call DevOps engineer:

**Notice → Investigate → Fix → Verify (with evidence)**

Every scenario folder includes its own `README.md` with the same structure:

- **Problem**
- **Solution**
- **Architecture Diagram**
- **Step-by-step CLI**
- **Screenshots**
- **Outcome**
- **Troubleshooting (extra tips + common causes)**

---

## What you’ll find here

### Current scenarios (examples in this folder)
- `crashloopbackoff-ops/` → App keeps restarting (**CrashLoopBackOff**)
- `dns-hostname-not-reso.../` → DNS/hostname not resolving (real networking issue)
- `k8s-imagepullbackoff/` → Pods stuck (**ImagePullBackOff**)
- `k8s-ingress-404-503/` → Ingress returns **404** or **503**
- `myapi-systemd-trouble.../` → Linux `systemd` service down (app won’t start / port not listening)
- `terraform-state-lock-re.../` → Terraform state lock issue (team blocked from deploy)

> Each folder is designed to be **reproducible** and **screenshot-friendly** like a real incident report.

---

## How I troubleshoot (my real ops flow)

1. **Confirm the impact**
   - Reproduce quickly with `curl`, browser, health endpoint, or a simple command.
2. **Collect signals**
   - Events, logs, status, endpoints, health checks.
3. **Find root cause**
   - Follow the chain: traffic → routing → service → pods/process → config/permissions.
4. **Apply the smallest safe fix**
   - Fix the cause, not the symptom.
5. **Verify recovery**
   - Pods healthy, endpoints restored, service reachable, errors stop.
6. **Capture proof**
   - Screenshots + CLI outputs saved in the scenario folder.


---

## Common commands I use all the time

### Kubernetes
```bash
kubectl get pods -A
kubectl describe pod <pod>
kubectl logs <pod> --tail=100
kubectl logs <pod> --previous --tail=100
kubectl get svc,endpoints -n <ns>
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp
kubectl rollout status deploy/<name> -n <ns>
````

### Linux (systemd)

```bash
sudo systemctl status <service> --no-pager
sudo journalctl -u <service> --no-pager -n 200
sudo ss -lntp
curl -I http://127.0.0.1:<port>/health
```

### Terraform

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform force-unlock <LOCK_ID>   # only when you confirm it is safe
```

---

## Folder standards (how I keep it consistent)

When I add a new troubleshooting scenario, I follow this structure:

```text
scenario-name/
├── README.md
├── screenshots/
│   ├── 01-symptom.png
│   ├── 02-logs-events.png
│   ├── 03-root-cause.png
│   └── 04-fix-verified.png
└── manifests/ or scripts/ (optional)
```

---

## Outcome (what this repo proves)

* I can troubleshoot **Kubernetes, Linux, Terraform, CI/CD** issues like real ops.
* I use a consistent method: **logs + events + verification**
* I always include **proof** (screenshots + CLI output) like a real incident trail.

---

