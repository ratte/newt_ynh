# Pnagolin for YunoHost

> *This package allows you to use Pangolin on your YunoHost server.*

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
- **Self-hosted Pangolin or Pangolin Cloud:** with a self-hosted Pangolin, `NO_CLOUD=true` makes sure Newt never falls back to Pangolin Cloud
- **Publishes YunoHost domains:** select domains in the config panel and Newt creates the matching Pangolin resources (via a Pangolin blueprint)
- **Real client IPs and fail2ban:** NGINX sees the real client IP, and fail2ban bans attackers in NGINX (firewall bans can't work through the tunnel)
- **Quiet diagnosis:** DNS, HTTP reachability and port checks that fail behind Pangolin by design are ignored for the published domains
- **Managed updates:** upgrades come through YunoHost; Newt's built-in self-updater is blocked because the binary is read-only for the app user
- **Configurable:** Pangolin endpoint, Newt ID, secret and log level are asked at install time; everything can be changed later in the webadmin config panel
- **Multi-instance:** connect one YunoHost server to several Pangolin sites or servers
- **Full YunoHost integration:** backup/restore, registered YunoHost service, log file with logrotate

### Before installing

Create a site in your Pangolin dashboard (**Sites > Add Site**, type **Newt**) and note the **endpoint**, **ID** and **secret** it shows you. After installing, select the YunoHost domains to publish in the app's config panel. Each domain must exist under *Domains* in your Pangolin organization.

### Limitations

- Pangolin SSH resources are not supported: the SSH auth daemon needs root and is disabled (`DISABLE_SSH=true`).
- Newt's self-updater logs an error every 6 hours because it can't replace its binary. This is expected.

See [doc/DESCRIPTION.md](doc/DESCRIPTION.md) and [doc/ADMIN.md](doc/ADMIN.md) for the full setup, real client IPs (fail2ban), diagnosis and mail caveats.

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

### Requirements

On the host machine:

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 7.x
- [Vagrant](https://developer.hashicorp.com/vagrant/install) 2.4 or newer (Ubuntu/LinuxMint-Setup:  [tests/vagrant/setup_vagrant_ubuntu.sh](tests/vagrant/setup_vagrant_ubuntu.sh))
- `rsync`, used for the synced folder (included on Linux and macOS; on Windows use WSL or the rsync from Cygwin/MSYS2)
- An x86_64 (amd64) CPU with hardware virtualization (VT-x/AMD-V) enabled in the BIOS/UEFI. Apple Silicon Macs are not supported: the box and the provisioning are amd64 only.
- About 2 GB of free RAM and 10 GB of free disk space
- Internet access while provisioning (Vagrant box, YunoHost installer, Newt release)

On Linux hosts, VirtualBox may refuse to start a VM while KVM is in use (for example by libvirt/QEMU). In that case stop those VMs or unload the `kvm_intel`/`kvm_amd` module first.

Check the installation:

```bash
vagrant --version
VBoxManage --version
rsync --version | head -1
```

### Running the tests

```bash
vagrant up                                              # Debian 13 + YunoHost 13 beta (first run ~15 min)
vagrant rsync                                           # after changing the package
vagrant ssh -c "sudo /vagrant/tests/vagrant/lifecycle.sh"
```

The lifecycle test covers install, permissions/sandbox, setting change + upgrade, config panel, backup, remove, restore and a second instance. Pass `EP=… ID=… SECRET=…` to test against a real Pangolin server.

The VM provisioning script itself has a quick unit test that runs on the host, without the VM or root (all system commands are stubbed): `tests/vagrant/provision_test.sh`.

To install the package manually in the VM (e.g. to try the web admin config panel):

```bash
vagrant rsync
# Interactive: asks for the Pangolin URL, Newt ID, secret and log level
vagrant ssh -c "sudo yunohost app install /vagrant --force"
# Or non-interactive, with your real Pangolin credentials
vagrant ssh -c "sudo yunohost app install /vagrant --force --args 'pangolin_endpoint=https://pangolin.example.org&newt_id=YOUR_ID&newt_secret=YOUR_SECRET&log_level=INFO'"
```

`--force` is needed because the VM runs the YunoHost 13 beta and the package doesn't come from the official catalog.

Check that Newt is running:

```bash
vagrant ssh -c "systemctl status newt; sudo tail -f /var/log/newt/newt.log"
```

With real credentials, the site shows up as online in Pangolin.

Test VM details:

- Last full lifecycle run: 123/123 passed on YunoHost 13.0.11 (Debian 13.7)
- Box `bento/debian-13`; YunoHost is installed from the trixie **testing** channel, since YunoHost 13 is still in beta and not yet published as stable
- Web admin: <https://192.168.56.10>, user `ynhadmin` / `Yunohost-Test-1234` (`admin` is reserved by YunoHost)
- `vagrant destroy -f && vagrant up` rebuilds the VM from scratch

## License

This package is licensed under the [AGPL-3.0](LICENSE), like Newt itself.
