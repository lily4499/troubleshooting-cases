#!/usr/bin/env bash
set -euo pipefail

echo "== Applying fix for myapi (create env file + restart) =="

# Create env folder + env file
sudo mkdir -p /etc/myapi
sudo cp -f ./configs/myapi.env /etc/myapi/myapi.env

# Secure permissions
sudo chown -R root:root /etc/myapi
sudo chmod 750 /etc/myapi
sudo chmod 640 /etc/myapi/myapi.env

# Restart service
sudo systemctl restart myapi

echo
echo "Verify:"
echo "  sudo systemctl status myapi --no-pager -l"
echo "  sudo ss -lntp | grep ':3000' || true"
echo "  curl -s http://localhost:3000/health"
