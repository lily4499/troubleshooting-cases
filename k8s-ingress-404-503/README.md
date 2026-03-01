
# Kubernetes Troubleshooting: Ingress Returns **404** or **503**

**Real Ops Incident — Traffic Rejected at the Edge, Then Fails at the Backend**

## Context

This project demonstrates how I troubleshoot one of the most common Kubernetes access failures in real operations: an application is deployed, DNS appears correct, Ingress exists, but users still cannot reach the service.

Instead of treating this as a simple config issue, I approach it like a real production incident. I validate the traffic path from the edge inward, isolate where routing fails, confirm whether the request is reaching the correct backend, and prove recovery with evidence.

This simulation reflects a realistic on-call scenario where the issue evolves through multiple symptoms:

* **404 Not Found** when the Ingress rule does not match the incoming request
* **503 Service Unavailable** when the rule matches but the backend service is not able to serve traffic

This project shows that I can troubleshoot Kubernetes networking issues methodically, identify root causes quickly, and restore application access with clear verification.

---

## Problem

**Incident:** users cannot access the application through Kubernetes Ingress even though the application appears deployed.

What made this issue operationally important is that the failure happened in two layers:

* First, the request reached the Ingress controller but did not match the expected rule, resulting in **404**
* After correcting the request path/host logic, traffic moved further but failed at the service/backend layer, resulting in **503**

This is exactly the kind of issue that causes confusion in shared environments because multiple components can look “present” while traffic is still broken:

* Ingress resource exists
* DNS or host expectation seems correct
* Service exists
* Pods are running

But traffic still fails because the routing chain is only as healthy as its weakest link.

The key troubleshooting question was:

**Is traffic failing at rule matching, service selection, endpoint discovery, or backend port routing?**

---

## Solution

I resolved the incident by following a structured ops troubleshooting flow that validates each hop in the request path.

My recovery approach was:

* Confirm the exact failure pattern first instead of guessing
* Separate **404** behavior from **503** behavior so each symptom could be traced to a different layer
* Validate the Ingress definition to confirm host, path, class, and backend mapping
* Inspect the Ingress controller behavior because its logs reveal whether the issue is rule-related or backend-related
* Verify that the Service correctly selects the intended pods
* Confirm whether endpoints exist and whether the backend port mapping is valid
* Retest after each fix until traffic returned successfully

Final root causes identified:

* **404** was caused by a **host mismatch**, so the Ingress rule did not match the request
* **503** was caused by a **Service selector mismatch**, which left the service with no active endpoints, plus an incorrect **targetPort** mapping

Once the selector and port configuration were corrected, Ingress successfully routed traffic to healthy backend pods and the application returned **200 OK**.

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

This troubleshooting path follows the real Kubernetes request flow:

**Client Request → Ingress Controller → Ingress Rule Match → Service → Endpoints → Pods**

The architecture matters because a failure at different layers produces different symptoms:

* **404** usually indicates the request reached the Ingress controller but did not match the expected rule
* **503** usually indicates the rule matched, but the backend service had no healthy endpoints or the upstream port/path was broken

This project demonstrates not only Kubernetes object awareness, but also how those objects behave together during real incident response.

---

## Workflow

## 1) Goal: Confirm the ingress controller is active before blaming the application

Before investigating the app itself, I first verified that the ingress layer was actually running and able to receive traffic. This prevents wasted time troubleshooting services or pods when the controller is not available.

**Screenshot**
![Ingress controller running](screenshots/01-ingress-controller-running.png)

---

## 2) Goal: Reproduce the incident with the intentionally broken environment

I deployed the application stack in a way that simulates realistic operator mistakes. The setup was designed to produce an Ingress access failure and force a layered investigation rather than a one-step fix.

This gave me a realistic failure scenario to troubleshoot end to end.

**Screenshot**
![Apply manifests](screenshots/02-apply-manifests.png)

---

## 3) Goal: Prove the first symptom is a routing mismatch at the ingress rule layer

The first validation showed **404 Not Found**, which told me the request was reaching the Ingress controller but not matching the rule the way I expected.

That immediately narrowed the problem space from “everything is broken” to “the rule match is wrong.”

**Screenshot**
![404 curl](screenshots/03-404-curl-wrong-host.png)

---

## 4) Goal: Inspect ingress behavior and confirm the rule definition

I reviewed the Ingress configuration to validate the expected host, path, class, and backend service mapping. This step was critical to confirm whether the request pattern aligned with the defined rule.

This is where I isolated the reason for the 404 and corrected the routing expectation.

**Screenshot**
![Ingress describe](screenshots/04-ingress-describe.png)

---

## 5) Goal: Confirm that the issue has moved deeper into the backend path

After fixing the rule-matching issue, the symptom changed from **404** to **503**.

That change mattered because it proved progress:

* The request was now matching the Ingress rule
* Traffic was moving past the edge
* The new failure was happening at the backend service or endpoint layer

**Screenshot**
![503 curl](screenshots/05-503-curl.png)

---

## 6) Goal: Use ingress controller evidence to identify backend failure signals

I checked the ingress controller evidence to understand why matched traffic still could not be served. This is one of the fastest ways to confirm whether the issue is caused by missing endpoints, service lookup problems, or upstream failures.

The controller output pointed directly to a backend availability problem.

**Screenshot**
![Controller logs](screenshots/06-controller-logs-no-endpoints.png)

---

## 7) Goal: Validate the service definition and identify routing mismatches

Next, I reviewed the Service behavior to confirm two critical details:

* Was the service selecting the correct pods?
* Was the service forwarding traffic to the correct application port?

This step exposed the configuration drift between the service definition and the actual application workload.

**Screenshot**
![Service ports](screenshots/07-service-describe.png)

---

## 8) Goal: Prove the service has no active endpoints

I then validated whether the Service actually had endpoints behind it. This is a decisive troubleshooting checkpoint because an Ingress can be correctly configured but still return **503** if the Service has nothing healthy to send traffic to.

The result confirmed the service had no valid backend targets.

**Screenshot**
![Endpoints empty](screenshots/08-endpoints-empty.png)

---

## 9) Goal: Trace the endpoint failure back to pod labeling

To explain why the service had no endpoints, I checked the pod labels and compared them to the service selector. This proved that the service was not selecting the intended pods.

This established the first backend root cause clearly and with evidence.

**Screenshot**
![Pods labels](screenshots/09-pods-labels.png)

---

## 10) Goal: Restore service-to-pod mapping so backend endpoints appear

After correcting the service selection logic, I revalidated the backend discovery path and confirmed that endpoints were now present.

This was the turning point where the service regained actual pod targets.

**Screenshot**
![Endpoints present](screenshots/10-endpoints-present.png)

---

## 11) Goal: Correct port routing so traffic reaches the application process

With endpoints restored, I then corrected the service port mapping so traffic would be forwarded to the application’s real listening port.

This removed the last backend routing issue and aligned the Service with the container’s actual port behavior.

**Screenshot**
![Service targetPort fixed](screenshots/11-service-targetport-8080.png)

---

## 12) Goal: Verify full recovery from ingress to application response

Finally, I retested the traffic path and confirmed the application was reachable successfully through Ingress.

This verified that the full chain was restored:

* rule match works
* service selects pods
* endpoints exist
* backend port mapping is correct
* application responds successfully

**Screenshot**
![Success curl](screenshots/12-success-curl-200.png)

---

## 13) Goal: Validate user-facing browser access

Beyond command-line verification, I also confirmed the application worked in the browser. This matters because ops recovery is not complete until the service is reachable the way users actually consume it.

**Screenshot**
![Browser success](screenshots/13-browser-success.png)

---

## Business Impact

This project demonstrates practical incident-response value in Kubernetes environments.

From a business perspective, this troubleshooting pattern reduces downtime because it avoids random guessing and focuses directly on the request path that users depend on.

Key operational value:

* Restores production access faster by isolating failures layer by layer
* Reduces mean time to resolution by distinguishing **404 edge routing issues** from **503 backend availability issues**
* Improves reliability by validating the full traffic chain instead of fixing only one object
* Produces clear evidence for post-incident review and team handoff
* Shows readiness for real platform operations where Ingress, Services, and application workloads must work together

This is the kind of troubleshooting skill that matters in real teams because customer-facing outages often come from configuration misalignment, not just crashed containers.

---

## Troubleshooting

### What I diagnosed

**404 Not Found**

* Request reached the Ingress controller
* Host/path did not match the configured rule
* Root cause: host mismatch during request testing

**503 Service Unavailable**

* Ingress rule matched the request
* Backend service could not serve traffic
* Root cause: Service selector mismatch created empty endpoints
* Additional issue: wrong target port prevented correct backend forwarding

### Troubleshooting logic I used

1. Confirm whether the symptom is **404** or **503**
2. Validate Ingress rule match behavior
3. Inspect ingress controller evidence
4. Verify Service selector and port mapping
5. Confirm whether endpoints exist
6. Validate pod labels and readiness
7. Retest after each correction until traffic is restored

### What this incident proves

This incident shows I can:

* read Kubernetes symptoms correctly
* separate edge-routing failures from backend failures
* trace traffic across Ingress, Service, Endpoints, and Pods
* apply targeted fixes instead of trial-and-error changes
* verify restoration with evidence

---

## Useful CLI

### Core validation commands

```bash
# Check ingress objects
kubectl get ingress -n demo
kubectl describe ingress demo-ingress -n demo

# Check service behavior
kubectl get svc -n demo
kubectl describe svc demo-svc -n demo

# Check endpoints
kubectl get endpoints -n demo demo-svc
kubectl describe endpoints -n demo demo-svc

# Check pods with labels
kubectl get pods -n demo -o wide --show-labels

# Check ingress controller logs
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=200

# Check recent events
kubectl get events -n demo --sort-by=.metadata.creationTimestamp
```

### Troubleshooting CLI by symptom

#### If Ingress returns 404

```bash
kubectl describe ingress demo-ingress -n demo
kubectl get ingress demo-ingress -n demo -o yaml
```

Use these to verify:

* host value
* path value
* ingressClassName
* backend service name and port

---

#### If Ingress returns 503

```bash
kubectl describe svc demo-svc -n demo
kubectl get endpoints -n demo demo-svc
kubectl get endpointslice -n demo -l kubernetes.io/service-name=demo-svc
kubectl get pods -n demo -o wide --show-labels
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=200
```

Use these to verify:

* service selector matches pod labels
* endpoints exist
* pods are ready
* targetPort points to the real container port
* ingress controller is reporting missing endpoints or upstream failures

---

#### If you suspect readiness or pod-side issues

```bash
kubectl describe pods -n demo -l app=demo-app
kubectl logs -n demo -l app=demo-app --tail=100
```

These help confirm:

* readiness probe failures
* container startup issues
* port/listener mismatch
* application-side errors

---

## Cleanup

After validation, I removed the test resources to leave the cluster clean and ready for future troubleshooting scenarios.

Typical cleanup scope:

* delete the demo namespace
* remove the test application resources
* optionally disable the ingress addon if it was only enabled for this lab

This keeps the environment tidy and prevents leftover test routes, services, or pods from affecting future work.

---

