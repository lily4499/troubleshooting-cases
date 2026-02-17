#!/usr/bin/env bash
set -euo pipefail

echo "== myapi troubleshooting commands =="

echo
echo "# Status"
echo "sudo systemctl status myapi --no-pager -l"

echo
echo "# Logs"
echo "sudo journalctl -u myapi -n 120 --no-pager"
echo "sudo journalctl -u myapi -f"

echo
echo "# Unit file"
echo "sudo systemctl cat myapi"

echo
echo "# Env file existence"
echo "sudo ls -l /etc/myapi/myapi.env"
echo "sudo cat /etc/myapi/myapi.env"

echo
echo "# Port + health"
echo "sudo ss -lntp | grep ':3000' || true"
echo "curl -s http://localhost:3000/health"

echo
echo "# Stability"
echo "sudo systemctl show myapi -p NRestarts -p ActiveEnterTimestamp"
