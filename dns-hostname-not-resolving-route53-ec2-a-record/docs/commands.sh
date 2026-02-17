#!/usr/bin/env bash
# Copy/paste command list for the DNS troubleshooting workflow (Route 53 -> EC2 Public IP)
# Update values as needed.

DOMAIN="lilianebooks.online"
WWW="www.lilianebooks.online"
EC2_PUBLIC_IP="X.X.X.X"

# 1) Find EC2 public IP (pick the right instance)
aws ec2 describe-instances \
  --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,Tags[?Key=='Name']|[0].Value]" \
  --output table

# 2) Verify hosted zone exists
aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN"

# 3) Get hosted zone id
HZ_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN" \
  --query "HostedZones[0].Id" \
  --output text)
echo "$HZ_ID"

# 4) List record sets
aws route53 list-resource-record-sets --hosted-zone-id "$HZ_ID" --output table

# 5) Validate nameserver delegation (must match registrar)
dig NS "$DOMAIN" +short

# 6) Baseline resolver check
dig "$DOMAIN" A +short
dig "$WWW" A +short

# 7) Multi-resolver checks
dig @8.8.8.8 "$DOMAIN" A +noall +answer
dig @1.1.1.1 "$DOMAIN" A +noall +answer
dig @9.9.9.9 "$DOMAIN" A +noall +answer

# 8) Authoritative query (replace with one NS from the NS output)
# dig @ns-xxxx.awsdns-xx.org "$DOMAIN" A +noall +answer

# 9) Trace if it still fails
dig "$DOMAIN" +trace
