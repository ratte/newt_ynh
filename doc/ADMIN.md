### Configuration panel

Everything is configured in the app's configuration panel (*Applications > Newt > Configuration* in the webadmin, or `yunohost app config set __APP__`). Saving regenerates `__INSTALL_DIR__/newt.env` and restarts the service.

- **Pangolin connection:** endpoint, Newt ID and secret. Leave the secret field empty to keep the current secret.
- **Published domains:** the YunoHost domains Pangolin should serve (see below).
- **Real client IPs:** see below.
- **Log level**

Pangolin Cloud (`*.pangolin.net`) is detected automatically. For a self-hosted Pangolin, `NO_CLOUD=true` makes sure Newt never falls back to Pangolin Cloud.

### Publishing YunoHost domains through Pangolin

Select the domains under **Published domains**. Newt then creates one HTTP resource per domain in Pangolin (through a Pangolin *blueprint*), targeting YunoHost's NGINX through the tunnel (`https://127.0.0.1:443`, with the domain as Host header and TLS server name). All apps of that domain, including apps installed later, are reachable through Pangolin.

Requirements and caveats:

- The domain (or its parent domain) must exist under *Domains* in your Pangolin organization, and its DNS must point to Pangolin.
- A resource created by hand in Pangolin for the same domain blocks the automatic one (`Resource already exists` in the log): delete it in Pangolin first.
- Unselecting a domain does **not** delete its resource in Pangolin. Delete it there.
- By default Pangolin's own login is disabled for these resources: YunoHost's login (SSO) protects the apps, as without Pangolin. Enable **Also require Pangolin login** to require both.
- Check the result in `/var/log/__APP__/__APP__.log` (`Blueprint application failed: …` shows Pangolin's error).

Pangolin terminates TLS with its own certificate. Once the domain's DNS points to Pangolin, YunoHost can no longer renew its Let's Encrypt certificate; that is fine, the internal certificate is only used on the tunnel.

To publish something else (another port, a raw TCP service), add a resource by hand in Pangolin, attached to this site.

### YunoHost diagnosis

The diagnosis checks DNS records, HTTP reachability and open ports against the server's own public IP, which fails by design behind Pangolin. With **Ignore diagnosis checks that fail behind Pangolin** (on by default), Newt ignores for each published domain the basic DNS records (A/AAAA) and the HTTP reachability check, and also ports 80/443 once every public YunoHost domain is published. Mail DNS records are still checked. The ignore filters are removed when you unselect a domain, turn the option off or remove the app.

### Real client IPs (fail2ban)

Without extra config, YunoHost sees every request coming through the tunnel as `127.0.0.1`: logs are useless and fail2ban can't ban anyone. With **Use real client IPs and ban attackers in nginx** (on by default):

- `/etc/nginx/conf.d/newt-realip.conf` makes NGINX take the client IP from the `X-Forwarded-For` header set by Pangolin, only for requests coming from localhost. Only the last entry added by Pangolin is used, so clients can't spoof it.
- Firewall bans don't help behind the tunnel, since all traffic comes from localhost. fail2ban's web jails (`yunohost`, `yunohost-portal`, `nginx-http-auth`, `recidive`) therefore also ban the IP in NGINX (`/etc/nginx/newt-banned-ips.conf`, answered with 403).

These files are shared by all Newt instances and removed when no instance uses the option anymore. Check bans with `fail2ban-client status yunohost`.

### Mail and other raw TCP services

Do **not** expose Postfix through a raw TCP resource targeting `localhost:25`: Postfix trusts `127.0.0.0/8`, which could turn your server into an open relay. If you must, target the server's LAN IP instead.

### Logs

`/var/log/__APP__/__APP__.log`

### Limitations

- The SSH auth daemon (Pangolin SSH resources) is disabled, because it needs root.
- Newt's built-in self-updater is switched off (`NEWT_SYSTEM_SUBSTRATE=CONTAINER`); updates come through YunoHost. If Newt prints a banner about a newer version with a `curl … | bash` command at startup, ignore it.
