# Newt for YunoHost

> *This package allows you to install Newt quickly and simply on a YunoHost server.*

## Overview

Newt is the site connector of [Pangolin](https://pangolin.net), a self-hosted tunneled reverse proxy. It connects your YunoHost server to a Pangolin server through an outgoing WireGuard tunnel, so Pangolin can publish your apps without any port forwarding.

**Shipped version:** 1.20.1~ynh1

See [doc/DESCRIPTION.md](doc/DESCRIPTION.md) and [doc/ADMIN.md](doc/ADMIN.md).

## Install

```bash
sudo yunohost app install https://github.com/ratte/newt_ynh --debug
```

## Developer info

```bash
sudo yunohost app upgrade newt -u https://github.com/ratte/newt_ynh --debug
tools/bump_version.sh 1.21.0   # bump to a new upstream release
```

## Links

- Upstream: <https://github.com/fosrl/newt>
- Pangolin docs: <https://docs.pangolin.net>

## Local testing (Vagrant + VirtualBox)

```bash
vagrant up                                              # Debian 12 + YunoHost 12 (first run ~15 min)
vagrant rsync                                           # after changing the package
vagrant ssh -c "sudo /vagrant/tests/vagrant/lifecycle.sh"
```

The lifecycle test covers install, permissions/sandbox, setting change + upgrade, backup, remove, restore and a second instance. Pass `EP=… ID=… SECRET=…` to test against a real Pangolin server.
