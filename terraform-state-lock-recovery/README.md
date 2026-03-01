
# Terraform Ops Scenario: State Lock Blocks `terraform apply`

## Context

I was working from my **local machine** using a Terraform backend stored in **S3** with a **DynamoDB lock table**. I was making a small infrastructure update in my production environment, and when I ran `terraform apply`, Terraform stopped because the state was locked.

This is a real ops situation because Terraform uses state locking to protect the infrastructure state file from being changed by two runs at the same time. In this kind of issue, I do not guess and I do not unlock blindly. I follow a safe workflow:

**simulate or confirm → investigate → fix safely → verify**

---

## Problem

I ran Terraform from my laptop and got a state lock error.

Example of the type of error I saw:

```text
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        8f6d3d2a-9c3b-4c7d-9d18-2f7b3b8a5b77
  Path:      my-tf-state-prod/envs/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       liliane@my-laptop
  Version:   1.6.6
  Created:   2026-02-10 21:41:02.913 -0500 EST
  Info:      Previous apply was interrupted (terminal closed / network drop)
```

This matters because a lock can mean one of two things:

* another Terraform run is still active
* a previous run was interrupted and left a stale lock behind

If I force-unlock without checking first, I could create **state corruption**, **drift**, or conflicting infrastructure changes.

---

## Solution

My approach was:

1. Confirm the lock and capture the **Lock ID**
2. Investigate whether Terraform was still running on my machine
3. Confirm the backend was healthy:

   * state file exists in S3
   * DynamoDB lock table is reachable
4. Inspect the lock record and prove whether it was stale
5. If stale, safely remove it
6. Run `plan` first, then `apply`, and capture proof

The goal was not just to remove the lock. The goal was to remove it **safely** and return Terraform to normal operation without risking the state file.

---

## Architecture

Terraform was running on my **local machine** and using:

* **S3** to store the remote Terraform state file
* **DynamoDB** to manage state locking
* **AWS account / role** for backend access

![Architecture Diagram](screenshots/architecture.png)

---

## Workflow

### 1. Confirm the issue from the local machine

**Goal:** prove this is happening from my laptop and capture the initial lock behavior.

I first confirmed I was on my local machine and reproduced the lock condition in a safe way for the lab. One terminal held the lock, and another terminal showed the lock error.

**Screenshots**

**Local machine proof**
Should show Terraform version, hostname, local username, and current working directory.

![Local machine proof](screenshots/00-local-version-proof.png)

**Terminal A holding the lock**
Should show `terraform apply` waiting at the confirmation prompt, which means the lock is active.

![Terminal A holding lock](screenshots/01-lock-held-terminal-a.png)

**Terminal B lock error**
Should show the state lock error with Lock ID, path, who created it, and created time.

![Lock error](screenshots/02-lock-error.png)

---

### 2. Confirm the correct environment

**Goal:** make sure I am in the correct Terraform repo and production environment before touching anything.

Before investigating further, I verified I was in the right project path and working against the expected environment.

**Screenshot**

**Correct repo and environment path**
Should show the correct project directory and the expected Terraform files for the prod environment.

![Correct repo](screenshots/03-correct-repo.png)

---

### 3. Capture the lock details clearly

**Goal:** collect the exact lock information needed for investigation and safe recovery.

I re-ran the command to clearly capture the lock details. The most important part here was the **Lock ID**, but I also paid attention to the backend path, who created the lock, and the timestamp.

**Screenshot**

**Lock details highlighted**
Should show the lock error details clearly, especially Lock ID, Who, Created time, and Path.

![Lock details](screenshots/04-lock-details-highlight.png)

---

### 4. Investigate whether Terraform is still running

**Goal:** prove that no active Terraform process is still running locally.

This is the point where I slow down and verify. If Terraform is still running somewhere, I do not unlock. I first confirm whether there is still an active local process.

**Screenshot**

**Local Terraform process check**
Should show no active Terraform apply process running on the machine.

![ps terraform](screenshots/05-ps-terraform.png)

---

### 5. Confirm backend connectivity

**Goal:** verify the backend configuration is healthy before deciding the lock is stale.

I rechecked backend access to make sure Terraform could still talk to the remote backend correctly.

**Screenshot**

**Terraform backend initialization success**
Should show successful backend initialization and no backend configuration errors.

![terraform init](screenshots/06-terraform-init.png)

---

### 6. Verify AWS identity

**Goal:** confirm I am in the correct AWS account and role.

Before checking S3 and DynamoDB, I verified the AWS identity being used. This protects me from troubleshooting the wrong account or wrong credentials.

**Screenshot**

**AWS identity check**
Should show the active AWS account, role, or user being used for this Terraform session.

![sts identity](screenshots/07-sts-identity.png)

---

### 7. Confirm the state file exists in S3

**Goal:** prove the state file is present and reachable in the backend bucket.

This step confirms that the remote state object exists where Terraform expects it.

**Screenshot**

**S3 state file exists**
Should show the Terraform state file present in the expected S3 location.

![s3 state file](screenshots/08-s3-state-file.png)

---

### 8. Confirm the DynamoDB lock table is healthy

**Goal:** verify the lock table exists and is available.

Because the locking mechanism depends on DynamoDB, I checked that the table itself was healthy and reachable.

**Screenshot**

**DynamoDB table check**
Should show the lock table details and confirm the table is active.

![dynamodb table](screenshots/09-dynamodb-table.png)

---

### 9. Inspect the lock record

**Goal:** prove whether the lock is stale before taking action.

This was the decision point. I checked the lock record and matched it against what I already knew:

* the lock was created by my local machine
* the timestamp was old
* no Terraform process was running
* I was not running Terraform anywhere else

That combination told me the lock was stale.

**Screenshot**

**DynamoDB lock entry**
Should show the lock record in DynamoDB and help confirm it is stale.

![dynamodb scan lock](screenshots/10-dynamodb-lock-scan.png)

---

### 10. Safely release the stale lock

**Goal:** remove the stale lock only after proving it is safe to do so.

Once I confirmed the lock was stale, I released it safely. I only do this after investigation. I do not use force-unlock as my first reaction.

**Screenshot**

**Force-unlock success**
Should show Terraform confirming that the state lock was successfully removed.

![force unlock](screenshots/11-force-unlock.png)

---

### 11. Verify with plan first

**Goal:** confirm Terraform is healthy again before making changes.

After unlocking, I ran a plan first. I do not jump straight into apply after a lock issue because I want to confirm the state is consistent and the proposed changes still make sense.

**Screenshot**

**Terraform plan success**
Should show a successful Terraform plan with no lock issue.

![plan](screenshots/12-plan.png)

---

### 12. Apply successfully

**Goal:** complete the deployment normally and confirm recovery is complete.

Once the plan looked correct, I applied the change and confirmed Terraform returned to normal operation.

**Screenshot**

**Terraform apply success**
Should show a successful apply completion after the lock issue was resolved.

![apply success](screenshots/13-apply-success.png)

---

## Business Impact

This kind of issue looks small, but it matters a lot in real operations.

By handling the lock safely, I was able to:

* protect the Terraform state from corruption
* avoid conflicting infrastructure changes
* reduce risk in a production environment
* restore deployment workflow without guessing
* keep proof of investigation and recovery for troubleshooting and audit

In a real team environment, this kind of discipline helps prevent outages, broken infrastructure state, and confusion between engineers working on the same environment.

---

## Troubleshooting

### Lock keeps coming back

Possible causes:

* another Terraform terminal is still open
* another apply is actually still running
* repeated retries are recreating the lock

What I check:

* running Terraform processes
* duplicate terminals or sessions
* whether someone else is using the same backend

---

### `force-unlock` says lock not found

Possible causes:

* the lock was already released
* wrong backend path
* wrong workspace
* wrong environment directory

What I verify:

* current workspace
* backend reinitialization
* correct environment folder

---

### DynamoDB scan shows nothing but Terraform still says locked

Possible causes:

* wrong table name
* wrong AWS account
* wrong AWS region
* wrong state key or path

What I verify:

* AWS identity
* configured region
* backend configuration
* state location in S3

---

### Access denied to S3 or DynamoDB

Possible cause:

* missing IAM permission or wrong assumed role

What I verify:

* active AWS identity
* backend bucket access
* DynamoDB table access

---

### Lock removed during an active apply

This is the worst-case scenario.

If that happens, I stop and validate state carefully before applying again. I want to make sure Terraform state still matches what exists in AWS.

---

## Useful CLI

These are the commands I used most in this workflow and for troubleshooting.

### General investigation

```bash
terraform version
hostname
whoami
pwd
ps aux | grep terraform
terraform init -reconfigure -backend-config=backend.hcl
aws sts get-caller-identity
```

### Backend validation

```bash
aws s3 ls s3://lily2026-s3-bucket/envs/prod/terraform.tfstate
aws dynamodb describe-table --table-name terraform-state-lock
aws dynamodb scan --table-name terraform-state-lock
```

### Lock troubleshooting

```bash
terraform apply -lock-timeout=0s
terraform force-unlock <LOCK_ID>
terraform workspace show
terraform plan -var-file=prod.tfvars -out tfplan
terraform apply tfplan
```

### Helpful troubleshooting checks

```bash
aws configure get region
terraform init -reconfigure
terraform plan
```

---

## Cleanup

If I am only doing this as a lab or demo, cleanup means:

* close the test terminals used for the lock simulation
* make sure no stale lock remains in DynamoDB
* confirm no pending Terraform process is still running
* keep the screenshots and notes as incident evidence
* leave the backend healthy for the next Terraform run

If the test created no infrastructure changes, then cleanup is mostly about making sure the backend is clean and operational again.

---

