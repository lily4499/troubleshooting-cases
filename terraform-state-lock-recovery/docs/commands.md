# Commands Used (State Lock Recovery)

## 1) Reproduce lock and capture lock info
terraform apply

## 2) Confirm workspace/env
terraform workspace show
terraform workspace list

## 3) Reconfigure backend
terraform init -reconfigure

## 4) Confirm AWS identity + region
aws sts get-caller-identity
aws configure get region

## 5) Check S3 state file exists
aws s3 ls s3://my-tf-state-prod/envs/prod/terraform.tfstate

## 6) Check DynamoDB lock table exists
aws dynamodb describe-table --table-name terraform-locks-prod

## 7) Inspect lock record (confirm stale)
aws dynamodb scan --table-name terraform-locks-prod

## 8) Confirm no terraform process is still running
ps aux | grep terraform

## 9) Unlock ONLY after verification (use Lock ID from error)
terraform force-unlock <LOCK_ID>
# or if needed:
terraform force-unlock -force <LOCK_ID>

## 10) Plan + Apply safely
terraform plan -out tfplan
terraform apply tfplan
