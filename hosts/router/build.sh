#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Decrypting router secrets..."
export ROUTER_WIFI_KEY=$(sops -d --extract '["router_wifi_key"]' "$REPO_ROOT/secrets/secret.yaml")
export ROUTER_PPPOE_USER=$(sops -d --extract '["router_pppoe_user"]' "$REPO_ROOT/secrets/secret.yaml")
export ROUTER_PPPOE_PASS=$(sops -d --extract '["router_pppoe_pass"]' "$REPO_ROOT/secrets/secret.yaml")
export ROUTER_VLESS_UUID=$(sops -d --extract '["vless_uuid_dfjay"]' "$REPO_ROOT/secrets/vps.yaml")

echo "Building OpenWrt image..."
nix build "$REPO_ROOT#openwrt-image" --impure "$@"

echo "Done: $(readlink -f result)/sysupgrade.bin"
