# Runbook: Terraform State Lock Recovery

## Goal
Safely recover from a blocked Terraform apply due to a state lock without corrupting state.

## Quick Checklist
1. Confirm correct repo/env/workspace
2. Confirm no active pipeline/apply is running
3. Verify backend (S3 state exists, DynamoDB table accessible)
4. Identify lock ID from the Terraform error
5. Force-unlock only if stale
6. Re-run plan/apply

## Commands (copy/paste)
terraform workspace show
terraform init -reconfigure
aws sts get-caller-identity
aws s3 ls s3://my-tf-state-prod/envs/prod/terraform.tfstate
aws dynamodb describe-table --table-name terraform-locks-prod
aws dynamodb scan --table-name terraform-locks-prod
ps aux | grep terraform
terraform force-unlock <LOCK_ID>
terraform plan -out tfplan
terraform apply tfplan
