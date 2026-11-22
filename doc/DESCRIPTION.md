Newt is the site connector of [Pangolin](https://pangolin.net), a self-hosted tunneled reverse proxy with identity and access control.

Newt opens an outgoing WireGuard tunnel (in user space) from your YunoHost server to your Pangolin server. Pangolin can then publish your YunoHost apps under its public domains, without opening or forwarding any port on the YunoHost side (works behind CGNAT, too).

### Features

- Outgoing connection only: no port forwarding, no public IP needed
- Runs unprivileged with systemd sandboxing, no Docker
- Publishes the YunoHost domains you select: Newt creates the Pangolin resources
- Real client IPs in NGINX, fail2ban bans attackers in NGINX
- Ignores the YunoHost diagnosis checks that fail behind Pangolin by design
- Everything configurable in the webadmin config panel
- Upgrades are handled by YunoHost (Newt's built-in self-updater is switched off)
