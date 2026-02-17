#!/usr/bin/env bash
set -euo pipefail

echo "== Installing myapi (systemd) =="

# Packages
sudo apt update
sudo apt install -y python3

# Create service user
sudo useradd --system --no-create-home --shell /usr/sbin/nologin myapi 2>/dev/null || true

# Create app directory + copy app
sudo mkdir -p /opt/myapi
sudo cp -f ./app/app.py /opt/myapi/app.py
sudo chown -R myapi:myapi /opt/myapi

# Install systemd unit
sudo cp -f ./systemd/myapi.service /etc/systemd/system/myapi.service
sudo systemctl daemon-reload

echo
echo "NOTE: We are NOT creating /etc/myapi/myapi.env yet on purpose."
echo "This will simulate the failure (missing env file)."
echo

# Enable + start (expected to fail)
sudo systemctl enable --now myapi || true

echo
echo "Check failure:"
echo "  sudo systemctl status myapi --no-pager -l"
echo "  sudo journalctl -u myapi -n 120 --no-pager"
