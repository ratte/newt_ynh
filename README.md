# Newt for YunoHost

> *This package allows you to install Newt quickly and simply on a YunoHost server.*

## Overview

Newt is the site connector of [Pangolin](https://pangolin.net), a self-hosted tunneled reverse proxy with identity and access control. It connects your YunoHost server to a Pangolin server through an outgoing WireGuard tunnel, so Pangolin can publish your apps without any port forwarding.

**Shipped version:** 1.20.1~ynh1

**Requires:** YunoHost ≥ 12.1.17 (amd64, arm64, armhf), multi-instance supported.

### How it works

```
Browser ──HTTPS──▶ Pangolin (VPS, public IP) ◀══ WireGuard tunnel ══ Newt ──▶ YunoHost NGINX (127.0.0.1:443) ──▶ your apps
```

1. Pangolin runs on a separate server with a public IP (typically a small VPS). Your public domains point there.
2. Newt runs on your YunoHost server and opens an **outgoing** WireGuard tunnel (in user space) to Pangolin.
3. Pangolin receives the requests, applies its authentication and access rules, and forwards them through the tunnel to YunoHost's NGINX.

Your YunoHost server needs no public IP and no open or forwarded ports, so it works behind CGNAT, mobile connections or restrictive routers.

### Features

- **Outgoing connection only:** no port forwarding, no public IP needed on the YunoHost side
- **Unprivileged and sandboxed:** runs as its own system user under strict systemd sandboxing (`ProtectSystem=strict`, no capabilities, syscall filter, …), no Docker
- **Self-hosted only:** `NO_CLOUD=true` makes sure Newt never falls back to Pangolin Cloud
- **Managed updates:** upgrades come through YunoHost; Newt's built-in self-updater is blocked because the binary is read-only for the app user
- **Configurable:** Pangolin endpoint, Newt ID, secret and log level are asked at install time and can be changed later with `yunohost app setting`
- **Multi-instance:** connect one YunoHost server to several Pangolin sites or servers
- **Full YunoHost integration:** backup/restore, registered YunoHost service, log file with logrotate

### Before installing

Create a site in your Pangolin dashboard (**Sites > Add Site**, type **Newt**) and note the **endpoint**, **ID** and **secret** it shows you. After installing, add one HTTP resource per YunoHost domain in Pangolin, targeting `https://127.0.0.1:443` with the real domain as Host header/SNI.

### Limitations

- Pangolin SSH resources are not supported: the SSH auth daemon needs root and is disabled (`DISABLE_SSH=true`).
- Newt's self-updater logs an error every 6 hours because it can't replace its binary. This is expected.

See [doc/DESCRIPTION.md](doc/DESCRIPTION.md) and [doc/ADMIN.md](doc/ADMIN.md) for the full setup, real client IPs (fail2ban) and mail caveats.

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
