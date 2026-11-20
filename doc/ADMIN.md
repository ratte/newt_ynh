### Publishing YunoHost apps through Pangolin

In Pangolin, add an HTTP resource per YunoHost domain/subdomain, attached to this site, with the target:

- Method: `https`, host: `127.0.0.1`, port: `443`
- Set the Host header / TLS server name (SNI) to the real domain, so that YunoHost's NGINX picks the right vhost
- Do **not** target port 80: YunoHost redirects HTTP to HTTPS, which would loop

Pangolin terminates TLS with its own certificate. Once the domain's DNS points to Pangolin, YunoHost can no longer renew its Let's Encrypt certificate; that is fine, the internal certificate is only used on the tunnel. Make sure Pangolin/Traefik does not reject it.

YunoHost's diagnosis will complain about DNS records and ports: you can mark those items as ignored.

### Real client IPs (fail2ban)

Without extra config, YunoHost sees every request as coming from `127.0.0.1`. Create `/etc/nginx/conf.d/pangolin-realip.conf`:

```nginx
set_real_ip_from 127.0.0.1;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

then run `nginx -t && systemctl reload nginx`.

### Mail and other raw TCP services

Do **not** expose Postfix through a raw TCP resource targeting `localhost:25`: Postfix trusts `127.0.0.0/8`, which could turn your server into an open relay. If you must, target the server's LAN IP instead.

### Changing credentials or log level

```bash
yunohost app setting __APP__ newt_secret -v 'NEW_SECRET'
yunohost app setting __APP__ newt_id -v 'NEW_ID'
yunohost app setting __APP__ pangolin_endpoint -v 'https://pangolin.example.org'
yunohost app setting __APP__ log_level -v DEBUG
yunohost app upgrade __APP__ --force
```

The upgrade regenerates `__INSTALL_DIR__/newt.env` from the settings and restarts the service.

### Logs

`/var/log/__APP__/__APP__.log`

### Limitations

- The SSH auth daemon (Pangolin SSH resources) is disabled, because it needs root.
- Newt's built-in self-updater can't write its binary and logs an error every 6 hours. This is expected; updates come through YunoHost.
