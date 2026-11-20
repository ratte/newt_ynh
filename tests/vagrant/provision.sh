#!/bin/bash
# Installs and post-installs YunoHost inside the test VM (idempotent).
set -euo pipefail

DOMAIN="ynh-test.local"
ADMIN_USER="admin"
ADMIN_PASS="Yunohost-Test-1234"

if [[ -f /etc/yunohost/installed ]]; then
    echo "YunoHost already installed, nothing to do."
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl ca-certificates

# -a = non-interactive
curl -fsSL https://install.yunohost.org | bash -s -- -a

yunohost tools postinstall \
    --domain "$DOMAIN" \
    --username "$ADMIN_USER" \
    --fullname "Admin Test" \
    --password "$ADMIN_PASS" \
    --ignore-dyndns \
    --force-diskspace

echo
echo "YunoHost ready: https://192.168.56.10 (user: $ADMIN_USER / $ADMIN_PASS)"
echo "Run the tests with: vagrant ssh -c \"sudo /vagrant/tests/vagrant/lifecycle.sh\""
