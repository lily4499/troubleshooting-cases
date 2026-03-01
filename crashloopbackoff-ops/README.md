
# Kubernetes: CrashLoopBackOff

## Real “Ops” Scenario

## Context

In real operations work, a pod failing once is not the real problem. The real problem is when it keeps restarting, never becomes stable, and the application stays unavailable to users.

This project shows how I handle a **CrashLoopBackOff** issue the same way I would in a real Kubernetes environment: I confirm the symptom, collect evidence, identify the root cause, apply the fix, and verify the workload is healthy again.

The issue I simulated is a very common one in production:

* The application depends on an environment variable called `APP_MODE`
* That variable is missing
* The container starts, fails immediately, exits with code `1`, and Kubernetes keeps retrying
* The pod enters **CrashLoopBackOff**
* I then fix the configuration and prove the deployment is stable again

---

## Problem

A Kubernetes pod can enter **CrashLoopBackOff** when the container keeps starting, failing, restarting, and failing again.

In this situation, the main operational risks are:

* the application never becomes available
* the deployment does not stabilize
* users cannot reach the service
* restart count keeps increasing
* the real root cause is hidden unless logs and events are checked carefully

What I observed in this project:

* the Deployment existed
* the pod was created
* the pod never stayed in `Ready`
* the application was not reachable through the Service
* Kubernetes kept restarting the container

The key ops question was simple:

**Why is the container failing immediately after startup?**

---

## Solution

I followed a practical incident workflow that I use in real operations:

* confirm the pod is crashing repeatedly
* capture evidence from logs and pod events
* identify the exact failure reason
* apply the configuration fix
* verify the rollout succeeds
* confirm the service is reachable again

For this demo, the root cause was:

* missing required environment variable: `APP_MODE`

The fix was:

* update the Deployment to provide `APP_MODE=prod`

After the fix:

* the pod stopped crashing
* the deployment rolled out successfully
* restarts stopped increasing
* the service became reachable again

---

## Architecture

This project is intentionally simple so the failure is easy to isolate and explain.

**Architecture flow:**

* A Kubernetes **Deployment** manages the `crash-demo` pod
* A **Service** exposes the application internally
* The application requires the `APP_MODE` environment variable at startup
* When that variable is missing, the container exits immediately
* Kubernetes restarts the container automatically
* After the Deployment is corrected, the pod becomes stable and the Service works normally

![Architecture Diagram](screenshots/architecture.png)

---

## Workflow

### Goal 1 — Confirm the crash pattern

The first goal was to verify that this was not a one-time restart, but a repeated failure pattern.

I checked the pod state and confirmed:

* pod status changed to `CrashLoopBackOff`
* restarts kept increasing
* the application never reached a healthy running state

**Screenshot goal:** show the pod repeatedly failing and entering `CrashLoopBackOff`.

![CrashLoopBackOff pods](screenshots/01-crashloop-get-pods.png)

---

### Goal 2 — Collect evidence from logs

The next goal was to capture the application error directly from container logs.

This is where I looked for:

* startup errors
* missing configuration
* application exit messages
* any clear clue about why the container stopped

The logs showed the startup failure and pointed to the missing required setting.

**Screenshot goal:** show the application error from logs.

![Logs show error](screenshots/02-logs-error.png)

---

### Goal 3 — Check the previous container run

In CrashLoopBackOff situations, the previous container logs often give the clearest clue because the container may restart too quickly.

I checked the previous run to confirm the real startup failure and isolate the root cause.

That evidence confirmed the app was failing because `APP_MODE` was missing.

**Screenshot goal:** show the previous container logs with the root-cause clue.

![Previous logs](screenshots/03-logs-previous.png)

---

### Goal 4 — Validate pod events and exit behavior

After checking logs, I reviewed the pod details to confirm:

* the exit reason
* the last container state
* Kubernetes restart behavior
* back-off events recorded by the scheduler

This step helped confirm that the failure was not networking, image pull, or scheduling related. It was an application startup failure caused by configuration.

**Screenshot goal:** show exit reason and restart/back-off events.

![Describe pod events](screenshots/04-describe-pod-events.png)

---

### Goal 5 — Apply the fix

Once I confirmed the root cause, I updated the Deployment to include the missing environment variable.

This was the recovery step that changed the deployment from unstable to healthy.

**Screenshot goal:** show proof that the configuration fix was applied.

![Fix applied](screenshots/05-fix-applied.png)

---

### Goal 6 — Verify rollout success

After the fix, I verified that the deployment recovered correctly.

What I wanted to see:

* pod moves to `Running`
* readiness becomes healthy
* rollout completes successfully
* restart count stops increasing

This is the key proof point in ops work: not just applying a fix, but proving the workload is stable after the change.

**Screenshot goal:** show successful rollout after the fix.

![Rollout success](screenshots/06-rollout-success.png)

---

### Goal 7 — Prove the pod is stable

I then checked the pod again to confirm the service was no longer stuck in a restart loop.

What mattered here:

* stable `Running` status
* healthy `Ready` state
* no ongoing restart increase

**Screenshot goal:** show the pod healthy and stable.

![Pods running](screenshots/07-pods-running.png)

---

### Goal 8 — Validate application reachability

The final goal was to prove that the application was not only running, but actually reachable again.

This closes the incident properly because a pod being “Running” does not always mean the service is usable. I validated the application from the service side as final proof.

**Screenshot goal:** show the application reachable after recovery.

![Browser success](screenshots/08-browser-success.png)

---

## Business Impact

This project reflects a real operational skill that matters in production environments.

By handling CrashLoopBackOff correctly, I can:

* reduce downtime faster during application startup failures
* identify root cause with evidence instead of guessing
* separate app issues from Kubernetes platform issues
* recover deployments safely and verify stability after the fix
* provide clear proof of diagnosis and resolution for incident review

From a business perspective, this matters because repeated pod crashes can lead to:

* service outage
* failed releases
* degraded customer experience
* delayed deployments
* wasted engineering time during troubleshooting

This project shows that I do not stop at “the pod is broken.” I follow the full ops path:

**verify → investigate → fix → prove recovery**

---

## Troubleshooting

### Missing or incorrect environment variable

This is one of the most common causes of CrashLoopBackOff in application deployments.

**What I look for:**

* app exits immediately
* logs show missing configuration
* exit code is visible in pod details

**Typical signs:**

* missing env var
* invalid config value
* ConfigMap or Secret not injected correctly

---

### Application starts but fails health checks

Sometimes the container is technically running, but readiness or liveness checks keep failing and Kubernetes restarts it.

**What I look for:**

* probe failures in pod events
* wrong path or wrong port
* application not ready fast enough

---

### Wrong image or image startup behavior

A bad image, wrong tag, or broken startup command can also cause rapid failures.

**What I look for:**

* incorrect image tag
* missing binary
* bad entrypoint
* application crash right after startup

---

### Port mismatch

The application may start on one port while the container spec, probe, or service expects another.

**What I look for:**

* application logs mention listening port
* service target port does not match
* readiness probe points to the wrong port

---

### Permissions or filesystem issues

The container may fail if it cannot write to a required path or does not have the correct runtime permissions.

**What I look for:**

* permission denied in logs
* volume mount problems
* security context mismatch

---

## Useful CLI

### Core investigation commands

```bash
kubectl get pods -n ops
kubectl get pods -n ops -w
kubectl get pods -n ops -o wide
kubectl logs -n ops <pod-name>
kubectl logs -n ops <pod-name> --previous
kubectl describe pod -n ops <pod-name>
kubectl rollout status deployment/crash-demo -n ops
kubectl describe deployment crash-demo -n ops
```

### Recovery commands

```bash
kubectl set env deployment/crash-demo -n ops APP_MODE=prod
kubectl apply -n ops -f k8s/deployment-fixed.yaml
```

### Validation commands

```bash
kubectl get svc -n ops
kubectl get pods -n ops
kubectl describe pod -n ops <new-pod-name>
kubectl -n ops port-forward svc/crash-demo 18080:80 --address 0.0.0.0
```

---

## Troubleshoot CLI

### Check latest pod events

```bash
kubectl get events -n ops --sort-by=.metadata.creationTimestamp
```

### Inspect deployment YAML

```bash
kubectl get deployment crash-demo -n ops -o yaml
```

### Inspect service YAML

```bash
kubectl get svc crash-demo -n ops -o yaml
```

### Inspect pod YAML

```bash
kubectl get pod -n ops <pod-name> -o yaml
```

### Check restart counts quickly

```bash
kubectl get pods -n ops
```

### Check container state and exit reason

```bash
kubectl describe pod -n ops <pod-name>
```

### Read logs from previous failed run

```bash
kubectl logs -n ops <pod-name> --previous
```

---

## Cleanup

After testing and validating the fix, I clean up the demo resources so the namespace does not keep running unnecessary workloads.

Typical cleanup includes:

* removing the deployment
* removing the service
* deleting the test namespace
* verifying all demo resources are gone

This keeps the cluster clean and avoids leaving failed test workloads behind.

---

