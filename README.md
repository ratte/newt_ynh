# Newt for YunoHost

> *This package allows you to install Newt quickly and simply on a YunoHost server.*

## Overview

Newt is the site connector of [Pangolin](https://pangolin.net), a self-hosted tunneled reverse proxy. It connects your YunoHost server to a Pangolin server through an outgoing WireGuard tunnel, so Pangolin can publish your apps without any port forwarding.

**Shipped version:** 1.20.1~ynh1

**Requires:** YunoHost ≥ 12.1.17 (amd64, arm64, armhf), multi-instance supported.

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
vagrant up                                              # Debian 13 + YunoHost 13 beta (first run ~15 min)
vagrant rsync                                           # after changing the package
vagrant ssh -c "sudo /vagrant/tests/vagrant/lifecycle.sh"
```

The lifecycle test covers install, permissions/sandbox, setting change + upgrade, backup, remove, restore and a second instance. Pass `EP=… ID=… SECRET=…` to test against a real Pangolin server.

Test VM details:

- Last full lifecycle run: 67/67 passed on YunoHost 13.0.11 (Debian 13.7)
- Box `bento/debian-13`; YunoHost is installed from the trixie **testing** channel, since YunoHost 13 is still in beta and not yet published as stable
- Web admin: <https://192.168.56.10>, user `ynhadmin` / `Yunohost-Test-1234` (`admin` is reserved by YunoHost)
- `vagrant destroy -f && vagrant up` rebuilds the VM from scratch

## License

This package is licensed under the [AGPL-3.0](LICENSE), like Newt itself.
