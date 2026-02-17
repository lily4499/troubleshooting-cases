#!/usr/bin/env bash
set -euo pipefail

# UPSERT Route 53 A record to an EC2 public IP (no app required).
#
# Requirements:
# - AWS CLI configured: aws sts get-caller-identity must work
# - Permissions: route53:ChangeResourceRecordSets, route53:ListHostedZonesByName
#
# Usage:
#   ./scripts/route53-upsert-a-record.sh lilianebooks.online X.X.X.X
#   ./scripts/route53-upsert-a-record.sh www.lilianebooks.online X.X.X.X
#
# Notes:
# - This script finds the hosted zone by root domain name (zone apex).
# - TTL default is 60 seconds for fast validation.

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <record_name> <public_ip>"
  exit 1
fi

RECORD_NAME="$1"
PUBLIC_IP="$2"

# Infer root zone name:
# If record is "www.lilianebooks.online" -> zone is "lilianebooks.online"
# If record is already apex -> zone is the same.
ZONE_NAME="$RECORD_NAME"
if [[ "$RECORD_NAME" == www.* ]]; then
  ZONE_NAME="${RECORD_NAME#www.}"
fi

# Ensure trailing dot for hosted zone lookup safety
if [[ "$ZONE_NAME" != *"." ]]; then
  ZONE_NAME="${ZONE_NAME}."
fi

echo "Looking up hosted zone for: $ZONE_NAME"
HZ_ID="$(aws route53 list-hosted-zones-by-name \
  --dns-name "$ZONE_NAME" \
  --query "HostedZones[0].Id" \
  --output text)"

if [[ -z "$HZ_ID" || "$HZ_ID" == "None" ]]; then
  echo "❌ Hosted zone not found for $ZONE_NAME"
  exit 2
fi

echo "Hosted Zone ID: $HZ_ID"
echo "UPSERT A record: $RECORD_NAME -> $PUBLIC_IP"

TMP_JSON="$(mktemp)"
cat > "$TMP_JSON" <<EOF
{
  "Comment": "UPSERT A record ${RECORD_NAME} -> ${PUBLIC_IP} (EC2 public IP, no app)",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD_NAME}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          { "Value": "${PUBLIC_IP}" }
        ]
      }
    }
  ]
}
