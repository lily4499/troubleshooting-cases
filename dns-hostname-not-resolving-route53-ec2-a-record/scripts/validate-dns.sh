#!/usr/bin/env bash
set -euo pipefail

# Validate DNS using multiple resolvers + optional authoritative NS.
#
# Usage:
#   ./scripts/validate-dns.sh lilianebooks.online
#   ./scripts/validate-dns.sh lilianebooks.online www.lilianebooks.online
#
# Optional env vars:
#   EXPECTED_IP="X.X.X.X"   # if set, script checks that the A record matches this IP
#   AUTH_NS="ns-xxxx.awsdns-xx.org"   # if set, also queries authoritative NS directly

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <hostname1> [hostname2 ...]"
  exit 1
fi

RESOLVERS=(
  "8.8.8.8"        # Google
  "1.1.1.1"        # Cloudflare
  "9.9.9.9"        # Quad9
  "208.67.222.222" # OpenDNS
)

echo "== DNS Validation =="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Resolvers: ${RESOLVERS[*]}"
echo "EXPECTED_IP: ${EXPECTED_IP:-<not set>}"
echo "AUTH_NS: ${AUTH_NS:-<not set>}"
echo

for HOST in "$@"; do
  echo "---- Host: $HOST ----"

  echo "[Baseline] default resolver -> A (short):"
  dig "$HOST" A +short || true
  echo

  for R in "${RESOLVERS[@]}"; do
    echo "[Resolver @$R] A answer:"
    dig @"$R" "$HOST" A +noall +answer || true
    echo
  done

  if [[ -n "${AUTH_NS:-}" ]]; then
    echo "[Authoritative @$AUTH_NS] A answer:"
    dig @"$AUTH_NS" "$HOST" A +noall +answer || true
    echo
  fi

  if [[ -n "${EXPECTED_IP:-}" ]]; then
    echo "[Check EXPECTED_IP] ensuring $HOST resolves to $EXPECTED_IP on major resolvers..."
    for R in "8.8.8.8" "1.1.1.1" "9.9.9.9"; do
      GOT="$(dig @"$R" "$HOST" A +short | head -n1 || true)"
      if [[ "$GOT" != "$EXPECTED_IP" ]]; then
        echo "❌ MISMATCH on resolver $R: expected '$EXPECTED_IP' but got '$GOT'"
        exit 2
      fi
    done
    echo "✅ OK: $HOST matches EXPECTED_IP on major resolvers."
    echo
  fi

  echo "[Trace] +trace (use when troubleshooting):"
  echo "dig $HOST +trace"
  echo
done

echo "Done."
