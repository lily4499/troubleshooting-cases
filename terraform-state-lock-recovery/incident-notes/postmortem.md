# Incident Postmortem: Terraform State Lock Blocked Apply

## Summary
Terraform `apply` failed because the remote backend state was locked. The lock was created by a previous Jenkins run that failed and did not release the lock cleanly.

## Impact
- Terraform changes could not be applied to the prod environment until the lock was safely cleared.
- Deployment window delayed while verifying no concurrent apply was running.

## What Happened (Timeline)
- **2026-02-10 21:41 EST**: Jenkins job `prod-network-apply #214` failed during `terraform apply`.
- **2026-02-10 21:55 EST**: I attempted `terraform apply` and hit `Error acquiring the state lock`.
- **2026-02-10 22:05 EST**: Verified backend health (S3 state object exists, DynamoDB lock table reachable).
- **2026-02-10 22:10 EST**: Confirmed no active Terraform process/pipeline was running.
- **2026-02-10 22:12 EST**: Removed stale lock using `terraform force-unlock <LOCK_ID>`.
- **2026-02-10 22:15 EST**: Re-ran `plan` and `apply` successfully.

## Evidence / Lock Details (from Terraform error)
- **Lock ID:** 8f6d3d2a-9c3b-4c7d-9d18-2f7b3b8a5b77
- **Who:** jenkins@ip-10-0-2-15
- **Operation:** OperationTypeApply
- **Path:** my-tf-state-prod/envs/prod/terraform.tfstate
- **Created:** 2026-02-10 21:41:02 -0500 EST

## Root Cause
A Jenkins Terraform run failed/crashed and left a stale lock in the DynamoDB lock table.

## Resolution
Confirmed no active apply was running, validated backend resources, then safely removed the lock with `terraform force-unlock` using the lock ID from the error.

## What I Learned
- Never unlock blindly. Always verify no concurrent Terraform run is active.
- Capture lock metadata (ID/Who/Time/Path) every time for audit trail.

## Preventive Actions
- Add a pipeline step to fail fast and notify when lock acquisition fails.
- Ensure Terraform jobs are single-threaded per environment (one job at a time).
- Use short lock TTL practices (keep applies small, avoid long-running operations).
