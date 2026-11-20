#!/bin/bash
# Installs and post-installs YunoHost inside the test VM (idempotent).
set -euo pipefail

DOMAIN="ynh-test.local"
ADMIN_USER="ynhadmin"   # "admin" is reserved by YunoHost
ADMIN_PASS="Yunohost-Test-1234"

if [[ -f /etc/yunohost/installed ]]; then
    echo "YunoHost already installed, nothing to do."
    exit 0
fi

if ! command -v yunohost >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    # linux-headers-amd64: lets the VirtualBox Guest Additions rebuild their
    # modules for the kernel the YunoHost installer upgrades to.
    apt-get install -y -qq curl ca-certificates linux-headers-amd64

    # The Bento box has no GRUB install device in debconf; without this the
    # grub-pc upgrade aborts the non-interactive YunoHost install.
    echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections

    # YunoHost 13 (trixie) is only published in the "testing" channel so far.
    # -a = non-interactive, -d = distribution channel
    curl -fsSL https://install.yunohost.org/trixie | bash -s -- -a -d testing
fi

yunohost tools postinstall \
    --domain "$DOMAIN" \
    --username "$ADMIN_USER" \
    --fullname "Admin Test" \
    --password "$ADMIN_PASS" \
    --ignore-dyndns \
    --force-diskspace

# YunoHost restricts SSH via "AllowGroups ssh.main sftp.main ssh.app sftp.app admins root";
# keep "vagrant ssh" working by putting the vagrant user in a local ssh.app group.
groupadd -f ssh.app
usermod -aG ssh.app vagrant

echo
echo "YunoHost ready: https://192.168.56.10 (user: $ADMIN_USER / $ADMIN_PASS)"
echo "Run the tests with: vagrant ssh -c \"sudo /vagrant/tests/vagrant/lifecycle.sh\""
